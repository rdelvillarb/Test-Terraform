#!/usr/bin/sh

#
export ANSIBLE_HOST_KEY_CHECKING=False

# env
GOOGLE_APPLICATION_CREDENTIALS="/tmp/sa1-294.json" #!!!!!!!!!!! MANDATORY

# requisites
GCLOUD_PROJECT_NAME=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep project_id | cut -d\" -f 4)
CHALLENGE2_WORKDIR=$(pwd)
GCLOUD_BIN=$(which gcloud)
PYTHON3_BIN=$(which python3)
PIP_BIN=$(which pip)

# necessary
GCLOUD_ZONE="us-central1-a"

# output
output() {
  echo "Settings : "
  echo " CHALLENGE2_WORKDIR = $CHALLENGE2_WORKDIR"
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
create_instance_gcloud() {
  echo "create_instance ..."

  cd $CHALLENGE2_WORKDIR
  
  #roles
  ansible-galaxy role install -r requirements.yml -p role

  #vm
  SA_ACCOUNT_MAIL=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep client_email | cut -d\" -f 4)
  SA_ACCOUNT_PROJECT=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep project | cut -d\" -f 4)
  SA_ACCOUNT_FILE=$GOOGLE_APPLICATION_CREDENTIALS
  sed -e "s;SA_ACCOUNT_MAIL;$SA_ACCOUNT_MAIL;g" -e "s;SA_ACCOUNT_PROJECT;$SA_ACCOUNT_PROJECT;g" -e "s;SA_ACCOUNT_FILE;$SA_ACCOUNT_FILE;g" gce-instances-create.yaml.template > gce-instances-create.yaml
  ansible-playbook -e instances="vm1" -vv gce-instances-create.yaml

}

ansible_apply_jenkins() {
  echo "ansible apply jenkins app ..."

  IP=$(gcloud compute instances describe vm1 --zone $GCLOUD_ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
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

  # python3 && pip
  [ $($PYTHON3_BIN --version | grep "Python 3.*" | wc -l) -eq "1" ] || { echo python3 is not installed;
    help
    exit 0;
  }
  [ $($PIP_BIN --version | grep "python" | wc -l) -eq "1" ] || { echo pip is not installed;
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
  SA_ACCOUNT_MAIL=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep client_email | cut -d\" -f 4)
  SA_ACCOUNT_PROJECT=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep project | cut -d\" -f 4)
  SA_ACCOUNT_FILE=$GOOGLE_APPLICATION_CREDENTIALS
  sed -e "s;SA_ACCOUNT_MAIL;$SA_ACCOUNT_MAIL;g" -e "s;SA_ACCOUNT_PROJECT;$SA_ACCOUNT_PROJECT;g" -e "s;SA_ACCOUNT_FILE;$SA_ACCOUNT_FILE;g" gce-instances-delete.yaml.template > gce-instances-delete.yaml
  ansible-playbook -e instances="vm1" -vv gce-instances-delete.yaml
  echo Y | gcloud compute --project=$GCLOUD_PROJECT_NAME firewall-rules delete custom-allow-jenkins
}

# create
create() {
  init
  create_instance_gcloud # with gcloud
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
