provider "google-beta" {
  project = var.project_id
}

resource "google_tpu_v2_vm" "tpu_vm" {
  provider          = google-beta
  name              = var.vm_name
  zone              = var.zone
  accelerator_type  = var.accelerator_type
  runtime_version   = var.runtime_version

  network_config {
    can_ip_forward      = true
    enable_external_ips = true
  }

  scheduling_config {
    preemptible = var.use_spot
    reserved    = false
  }
}
