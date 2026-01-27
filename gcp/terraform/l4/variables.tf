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
  default     = true
}

variable "auto_deploy" {
  description = "Whether to automatically deploy ComfyUI"
  type        = bool
  default     = true
}

variable "download_models" {

  description = "Whether to automatically download models"

  type = bool

  default = true

}



variable "machine_type" {

  description = "The instance type to use"

  type = string

  default = "g2-standard-8"

}
