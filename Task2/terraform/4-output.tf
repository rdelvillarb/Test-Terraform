output "id" {
  value       = google_compute_instance.vm-linux.id
  description = "an identifier for the resource with formate"
}

output "instance_id" {
  value       = google_compute_instance.vm-linux.instance_id
  description = "The server-assigned unique identifier of this instance"
}

output "cpu_platform" {
  value       = google_compute_instance.vm-linux.cpu_platform
  description = "The CPU platform used by this instance"
}
output "vm-linux-internal-ip" {
  value      = google_compute_instance.vm-linux.network_interface.0.network_ip
  depends_on = [google_compute_instance.vm-linux]
}

output "vm-linux-ephemeral-ip" {
  value      = google_compute_instance.vm-linux.network_interface.0.access_config.0.nat_ip
  depends_on = [google_compute_instance.vm-linux]
}

