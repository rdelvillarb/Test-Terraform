locals {

  project_id       = "test-339001"
  region           = "us-central1"
  zone             = "us-central1-a"
  image            = "ubuntu-2004-focal-v20211212"
  machine          = "n1-standard-1"
  private_key_path = "id_rsa.pub"
  ssh_user         = "ansible"
  gke_num_nodes    = 2

}