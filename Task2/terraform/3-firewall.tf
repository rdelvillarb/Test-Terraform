# allow http traffic
resource "google_compute_firewall" "allow-http" {
  name    = "tf-fw-allow-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http"]
}

# allow ssh traffic
resource "google_compute_firewall" "allow-ssh" {
  name    = "tf-fw-allow-ssh"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh"]
}