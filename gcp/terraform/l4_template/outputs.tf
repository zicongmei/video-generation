output "template_name" {
  description = "The name of the VM template"
  value       = google_compute_instance_template.vm_template.name
}

output "template_self_link" {
  description = "The self-link of the VM template"
  value       = google_compute_instance_template.vm_template.self_link
}
