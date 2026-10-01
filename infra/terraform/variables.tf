variable "aws_region" {
  description = "AWS region in which to create the infrastructure."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "cloudops-servicehub"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "additional_tags" {
  description = "Additional tags to apply to every supported AWS resource."
  type        = map(string)
  default     = {}
}

variable "ssh_allowed_cidr" {
  description = "Optional single public IPv4 /32 allowed to use SSH. Leave null to disable SSH ingress."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.ssh_allowed_cidr == null || (can(cidrnetmask(var.ssh_allowed_cidr)) && endswith(var.ssh_allowed_cidr, "/32"))
    error_message = "ssh_allowed_cidr must be null or a valid single-host IPv4 /32 CIDR."
  }
}

variable "key_name" {
  description = "Optional existing EC2 key pair name. Required only when ssh_allowed_cidr is set."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "ARM64 EC2 instance type for the ServiceHub host."
  type        = string
  default     = "t4g.micro"
}

variable "enable_https_ingress" {
  description = "Whether to allow public HTTPS traffic. Keep false until an HTTPS listener and certificate are configured."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Size of the encrypted EC2 root volume in GiB."
  type        = number
  default     = 10

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "root_volume_size must be between 8 and 30 GiB for this learning environment."
  }
}
