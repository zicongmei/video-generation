output "vm_name" {
  description = "The name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "vm_zone" {
  description = "The zone of the VM instance"
  value       = google_compute_instance.vm_instance.zone
}

output "vm_public_ip" {
  description = "The public IP address of the VM instance"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
