output "vm_name" {
  description = "The name of the TPU VM instance"
  value       = google_tpu_v2_vm.tpu_vm.name
}

output "vm_zone" {
  description = "The zone of the TPU VM instance"
  value       = google_tpu_v2_vm.tpu_vm.zone
}

output "vm_public_ip" {
  description = "The public IP address of the TPU VM instance"
  value       = google_tpu_v2_vm.tpu_vm.network_endpoints[0].access_config[0].external_ip
}
