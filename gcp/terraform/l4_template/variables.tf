variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "template_name" {
  description = "The name of the VM template"
  type        = string
  default     = "video-gen-l4-template"
}

variable "disk_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 200
}

variable "auth_username" {
  description = "Username for ComfyUI authentication"
  type        = string
}

variable "auth_password" {
  description = "Password for ComfyUI authentication"
  type        = string
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

variable "machine_type" {
  description = "The instance type to use"
  type        = string
  default     = "g2-standard-8"
}
