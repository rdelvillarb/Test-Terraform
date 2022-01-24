#!/usr/bin/sh

# env
GOOGLE_APPLICATION_CREDENTIALS="/tmp/test_challenge_key.json" #!!!!!!!!!!! MANDATORY

# requisites
GCLOUD_PROJECT_NAME=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep project_id | cut -d\" -f 4)
TASK2_WORKDIR=$(pwd)
GCLOUD_BIN=$(which gcloud)
PYTHON3_BIN=$(which python3)
PIP_BIN=$(which pip)
TERRAFORM_BIN=$(which terraform)
KUBECTL_BIN=kubectl

# necessary
GCLOUD_REGION="us-central1"
GCLOUD_ZONE="us-central1-a"
GCLOUD_IMAGE="ubuntu-2004-focal-v20211212"
GCLOUD_MACHINE="n1-standard-1"
GCLOUD_SSH_USER="ansible"
GCLOUD_NUM_NODES=1


# output
output() {
  echo "Settings : "
  echo " TASK2_WORKDIR = $TASK2_WORKDIR"
  echo " GOOGLE_APPLICATION_CREDENTIALS = $GOOGLE_APPLICATION_CREDENTIALS"
  echo " GCLOUD_BIN = $GCLOUD_BIN"
  echo " GCLOUD_ZONE = $GCLOUD_ZONE"
  echo " GCLOUD_PROJECT_NAME = $GCLOUD_PROJECT_NAME"
}

# help
help() {
  echo "help ..."
  echo " Define variables:"
  echo " * GOOGLE_APPLICATION_CREDENTIALS = </tmp/auth.json>"
  echo " Connect to:"
  echo " * http://<EXTERNAL_IP>:8080"
  echo " External IP:"
  echo " - gcloud compute instances describe <VM_NAME> --zone <VM_ZONE> --format='get(networkInterfaces[0].accessConfigs[0].natIP)'"
  echo " Python3.*"
  echo " pip modules apache-libcloud pycrypto ansible"
}

# 
create_instance_terraform() {
  echo "create_instance ..."

  cd $TASK2_WORKDIR
  
  #roles
  ansible-galaxy role install -r requirements.yml -p role

 
  sed -e "s@PROJECT_ID@$GCLOUD_PROJECT_NAME@g" -e "s@REGION@$GCLOUD_REGION@g" -e "s@ZONE@$GCLOUD_ZONE@g -e "s@MACHINE@$GCLOUD_MACHINE@g -e "s@IMAGE_NAME@$GCLOUD_IMAGE@g -e "s@CREDENCIALS@$GOOGLE_APPLICATION_CREDENTIALS@g" -e "s@SSH_USER@$GCLOUD_SSH_USER@g" -e "s@GKE_NUM_NODES@$GCLOUD_NUM_NODES@g" $TASK2_WORKDIR/terraform/0-variables.tf.template > $TASK2_WORKDIR/terraform/0-variables.tf
  $TERRAFORM_BIN -chdir=$TASK2_WORKDIR/terraform fmt
  $TERRAFORM_BIN -chdir=$TASK2_WORKDIR/terraform init
  $TERRAFORM_BIN -chdir=$TASK2_WORKDIR/terraform apply -auto-approve

}


ansible_apply_jenkins() {
  echo "ansible apply jenkins app ..."

  IP=$(gcloud compute instances describe vm-linux --zone $GCLOUD_ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
  echo $IP
  sed -e "s;IP;$IP;g" hosts.template > hosts
  ansible-playbook -i hosts -v playbook_install_jenkins.yaml
  gcloud compute --project=$GCLOUD_PROJECT_NAME firewall-rules create custom-allow-jenkins --description="Jenkins TCP 8080" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:8080 --source-ranges=0.0.0.0/0 --target-tags=ansible
}

# check 
init() {

  # test google_applicatiion_credentials
  test -e "$GOOGLE_APPLICATION_CREDENTIALS" || { echo "$GOOGLE_APPLICATION_CREDENTIALS" not existing;
    help
    exit 0;
  }
  test -e "$GCLOUD_BIN" || { echo gcloud is not installed;
    help
    exit 0;
  }

  echo "Environment ... "
  output

  # basic authentication and set projecdt
  $GCLOUD_BIN auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
  $GCLOUD_BIN config set project $GCLOUD_PROJECT_NAME 
  echo Y | $GCLOUD_BIN services enable cloudresourcemanager.googleapis.com
  echo Y | $GCLOUD_BIN services enable cloudbuild.googleapis.com
}

# destroy
destroy() {
  init
  
  #vm
  $TERRAFORM_BIN -chdir=$TASK2_WORKDIR/terraform destroy -auto-approve
  echo Y | gcloud compute --project=$GCLOUD_PROJECT_NAME firewall-rules delete custom-allow-jenkins
}

# create
create() {
  init
  create_instance_terraform 
  ansible_apply_jenkins 
}

case "$1" in
  "destroy" ) echo "call destroy ..." && destroy
	  ;;
  "create" ) echo "call create ..." && create
	  ;;
  "output" ) echo "call output ..." && output
	  ;;
  *) echo "exit" && help 
esac
