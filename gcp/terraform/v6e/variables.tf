variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "zone" {
  description = "The zone to deploy the TPU VM in"
  type        = string
  default     = "us-east5-b"
}

variable "vm_name" {
  description = "The name of the TPU VM"
  type        = string
}

variable "auth_username" {
  description = "Username for authentication"
  type        = string
  default     = "root"
}

variable "auth_password" {
  description = "Password for authentication"
  type        = string
  default     = "qps564"
}

variable "accelerator_type" {
  description = "The type of TPU accelerator"
  type        = string
  default     = "v6e-1"
}

variable "runtime_version" {
  description = "The TPU runtime version"
  type        = string
  default     = "v2-alpha-tpuv6e"
}

variable "use_spot" {
  description = "Whether to use a spot instance"
  type        = bool
  default     = true
}
