# VM
resource "google_compute_instance" "vm-linux" {
  name         = "vm-linux"
  zone         = local.zone
  machine_type = local.machine
  boot_disk {
    initialize_params {
      image = local.image
    }
  }

  # Add SSH access to the Compute Engine instance
  metadata = {
    #  ssh-keys = "${local.gcp_username}:${file("id_rsa.pub")}"
    ssh-keys = "${local.ssh_user}:${file(local.private_key_path)}"
  }

  # Startup script
  # metadata_startup_script = "${file("update-vm.sh")}"

  network_interface {
    network    = "default"
    subnetwork = "default"

    access_config {}
  }

  #    provisioner "remote-exec" {
  #      inline = ["echo 'Wait until SSH is ready'"]
  #  
  #      connection {
  #        type        = "ssh"
  #        user        = local.ssh_user
  #        private_key = file(local.private_key_path)
  #        host        = google_compute_instance.vm-linux.network_interface.0.access_config.0.nat_ip
  #      }
  #    }

  #provisioner "local-exec" {
  #  command = "ansible-playbook  -i ${google_compute_instance.vm-linux.network_interface.0.access_config.0.nat_ip}, --private-key ${file(local.private_key_path)} install_Jenkins.yaml"
  #}
}

