#!/usr/bin/sh
# env
GOOGLE_APPLICATION_CREDENTIALS="/tmp/test_challenge_key.json" #!!!!!!!!!!! MANDATORY

# requisites
GCLOUD_PROJECT_NAME=$(cat $GOOGLE_APPLICATION_CREDENTIALS | grep project_id | cut -d\" -f 4)
TASK1_WORKDIR=$(pwd)
GCLOUD_BIN=gcloud #$(which gcloud)
TERRAFORM_BIN=$(which terraform)
KUBECTL_BIN=kubectl

# necessary
GCLOUD_ZONE="us-east1"
GCLOUD_CLUSTER_NAME="$GCLOUD_PROJECT_NAME-gke"
GCLOUD_NUM_NODES=1
DOCKER_IMAGE_NAME="img-task"
DOCKER_IMAGE_TAG="v1"
GCLOUD_IMAGE_NAME="gcr.io/$GCLOUD_PROJECT_NAME/$DOCKER_IMAGE_NAME"
GCLOUD_IMAGE_TAG=$DOCKER_IMAGE_TAG

# output
output() {
  echo "Settings : "
  echo " TASK1_WORKDIR = $TASK1_WORKDIR"
  echo " GOOGLE_APPLICATION_CREDENTIALS = $GOOGLE_APPLICATION_CREDENTIALS"
  echo " GCLOUD_BIN = $GCLOUD_BIN"
  echo " GCLOUD_ZONE = $GCLOUD_ZONE"
  echo " GCLOUD_CLUSTER_NAME = $GCLOUD_CLUSTER_NAME"
  echo " GCLOUD_NUM_NODES = $GCLOUD_NUM_NODES"
  echo " GCLOUD_PROJECT_NAME = $GCLOUD_PROJECT_NAME"
  echo " DOCKER_IMAGE_NAME = $DOCKER_IMAGE_NAME"
  echo " DOCKER_IMAGE_TAG = $DOCKER_IMAGE_TAG"
  echo " GCLOUD_IMAGE_NAME = $GCLOUD_IMAGE_NAME"
  echo " GCLOUD_IMAGE_TAG = $GCLOUD_IMAGE_TAG"
}

# help
help() {
  echo "help ..."
  echo " Define variables:"
  echo " * GOOGLE_APPLICATION_CREDENTIALS = </tmp/auth.json>"
  echo " Connect to:"
  echo " * http://<EXTERNAL_IP>/"
  echo " * http://<EXTERNAL_IP>/greetings"
  echo " * http://<EXTERNAL_IP>/square/<number>"
  echo " External IP:"
  echo " - kubectl get svc"
}

# terraform cluster
gke_terraform() {
  echo "gke_terraform ..."
  sed -e "s@PROJECT_ID@$GCLOUD_PROJECT_NAME@g" -e "s@REGION@$GCLOUD_ZONE@g" -e "s@CREDENCIALS@$GOOGLE_APPLICATION_CREDENTIALS@g" -e "s@GKE_NUM_NODES@$GCLOUD_NUM_NODES@g" $TASK1_WORKDIR/terraform/0-variables.tf.template > $TASK1_WORKDIR/terraform/0-variables.tf
  $TERRAFORM_BIN -chdir=$TASK1_WORKDIR/terraform fmt
  $TERRAFORM_BIN -chdir=$TASK1_WORKDIR/terraform init
  $TERRAFORM_BIN -chdir=$TASK1_WORKDIR/terraform apply -auto-approve

}

# gcloud cluster
gke_image() {
  echo "gke_image ..."
  
  echo Y | $GCLOUD_BIN auth configure-docker

  echo $GCLOUD_IMAGE_NAME:$GCLOUD_IMAGE_TAG
  cd $TASK1_WORKDIR/api \
	  && $GCLOUD_BIN builds submit --tag $GCLOUD_IMAGE_NAME:$GCLOUD_IMAGE_TAG \
	  && cd $TASK1_WORKDIR

  echo $GCLOUD_IMAGE_NAME:$GCLOUD_IMAGE_TAG

  $GCLOUD_BIN container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE
  sed -e "s@IMAGE_NAME@$GCLOUD_IMAGE_NAME:$GCLOUD_IMAGE_TAG@g" $TASK1_WORKDIR/api/deployment.yaml.template > $TASK1_WORKDIR/api/deployment.yaml
  echo "Paso sed"
  $KUBECTL_BIN apply -f $TASK1_WORKDIR/api/deployment.yaml 
  $KUBECTL_BIN get all

}

# check 
init() {

  test -e "$GOOGLE_APPLICATION_CREDENTIALS" || { echo "$GOOGLE_APPLICATION_CREDENTIALS" not existing;
    help
    exit 0;
  }

  test "$GCLOUD_CLUSTER_NAME" || { echo GCLOUD_CLUSTER_NAME is not defined;
    help
    exit 0;
  }


  # basic authentication and set projecdt
  $GCLOUD_BIN auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
  $GCLOUD_BIN config set project $GCLOUD_PROJECT_NAME 
  echo Y | $GCLOUD_BIN services enable cloudresourcemanager.googleapis.com
  echo Y | $GCLOUD_BIN services enable cloudbuild.googleapis.com
}

# destroy
destroy() {
  init

  #Delete deployment  
  echo Y | $KUBECTL_BIN delete -f $TASK1_WORKDIR/api/deployment.yaml 
  
  #Destroy Cluster
  $TERRAFORM_BIN -chdir=$TASK1_WORKDIR/terraform destroy -auto-approve
  
  #Destroy Image
  echo Y | $GCLOUD_BIN container images delete $GCLOUD_IMAGE_NAME:$GCLOUD_IMAGE_TAG
}

# create
create() {
  init
  gke_terraform 
  gke_image
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
