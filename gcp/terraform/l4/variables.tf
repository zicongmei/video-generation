variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "zone" {
  description = "The zone to deploy the VM in"
  type        = string
  default     = "us-central1-a"
}

variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "disk_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 200
}

variable "auth_username" {
  description = "Username for ComfyUI authentication"
  type        = string
  default     = "root"
}

variable "auth_password" {
  description = "Password for ComfyUI authentication"
  type        = string
  default     = "qps564"
}

variable "use_spot" {
  description = "Whether to use a spot instance"
  type        = bool
  default     = false
}