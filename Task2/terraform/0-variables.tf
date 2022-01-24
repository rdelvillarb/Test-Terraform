locals {

  project_id       = "test-339001"
  region           = "us-central1"
  zone             = "us-central1-a"
  image            = "ubuntu-2004-focal-v20211212"
  machine          = "n1-standard-1"
  credentials      = "/tmp/test_challenge_key.json"
  ssh_user         = "ansible"
  private_key_path = "/tmp/id_rsa.pub"
  gke_num_nodes    = 1

}