# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "name" {
  default = "ppresto-mynginx"
}

variable "common_name" {
  default = "example.com"
}

variable "organization_name" {
  default = "Example Inc."
}

variable "provider" {
  default = "aws"
}

variable "local_ip_url" {
  default = "http://169.254.169.254/latest/meta-data/local-ipv4"
}

variable "download_certs" {
  default = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "vpc_cidr" {
  default = "10.139.0.0/16"
}

variable "vpc_cidrs_public" {
  type    = "list"
  default = ["10.139.1.0/24", "10.139.2.0/24", "10.139.3.0/24"]
}

variable "vpc_cidrs_private" {
  type    = "list"
  default = ["10.139.11.0/24", "10.139.12.0/24", "10.139.13.0/24"]
}

variable "nat_count" {
  default = 1
}

variable "bastion_servers" {
  default = 1
}

variable "bastion_instance" {
  default = "t2.small"
}

variable "bastion_release" {
  default = "0.1.0"
}

variable "bastion_consul_version" {
  default = "1.2.3"
}

variable "bastion_vault_version" {
  default = "0.11.3"
}

variable "bastion_os" {
  default = "RHEL"
}

variable "bastion_os_version" {
  default = "7.3"
}

variable "bastion_image_id" {
  default = ""
}

variable "network_tags" {
  type = "map"

  default = {
    "env" = "ppresto-mynginx"
  }
}

variable "consul_server_config_override" {
  default = ""
}

variable "consul_client_config_override" {
  default = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# Myapp Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "myapp_create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "myapp_name" {
  description = "Name for resources, defaults to \"consul-aws\"."
  default     = "myapp-aws"
}

variable "myapp_ami_owner" {
  description = "Account ID of AMI owners (Hashicrop, Ubuntu, ECS, CentOS )"

  #default     = ["012230895537", "099720109477", "591542846629", "679593333241"] # HashiCorp Public AMI AWS account
  default = "099720109477"
}

variable "install_packages" {
  description = "list of ubuntu packages for user_data script to install in addition to nginx"
  default     = "curl jq"
}

variable "nginx_httpport" {
  description = "nginx listen port"
  default     = 80
}

variable "myapp_release_version" {
  description = "Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1), defaults to \"0.1.0\", view releases at https://github.com/hashicorp/guides-configuration#hashistack-version-tables"
  default     = "0.1.0"
}

variable "myapp_os" {
  description = "Operating System (e.g. RHEL or Ubuntu), defaults to \"RHEL\"."
  default     = "RHEL"
}

variable "myapp_os_version" {
  description = "Operating System version (e.g. 7.3 for RHEL or 16.04 for Ubuntu), defaults to \"7.3\"."
  default     = "7.3"
}

variable "myapp_public" {
  description = "Open up nodes to the public internet for easy access - DO NOT DO THIS IN PROD, defaults to false."
  default     = true
}

variable "myapp_count" {
  description = "Number of Consul nodes to provision across private subnets, defaults to private subnet count."
  default     = -1
}

variable "myapp_instance_type" {
  description = "AWS instance type for Consul node (e.g. \"m4.large\"), defaults to \"t2.small\"."
  default     = "t2.micro"
}

variable "myapp_image_id" {
  description = "AMI to use, defaults to the HashiStack AMI."
  default     = ""
}

variable "myapp_instance_profile" {
  description = "AWS instance profile to use, defaults to consul-auto-join-instance-role module."
  default     = ""
}

variable "myapp_user_data" {
  description = "user_data script to pass in at runtime."
  default     = ""
}

variable "use_lb_cert" {
  description = "Use certificate passed in for the LB IAM listener, \"lb_cert\" and \"lb_private_key\" must be passed in if true, defaults to false."
  default     = false
}

variable "lb_cert" {
  description = "Certificate for LB IAM server certificate."
  default     = ""
}

variable "lb_private_key" {
  description = "Private key for LB IAM server certificate."
  default     = ""
}

variable "lb_cert_chain" {
  description = "Certificate chain for LB IAM server certificate."
  default     = ""
}

variable "lb_ssl_policy" {
  description = "SSL policy for LB, defaults to \"ELBSecurityPolicy-2016-08\"."
  default     = "ELBSecurityPolicy-2016-08"
}

variable "lb_bucket" {
  description = "S3 bucket override for LB access logs, `lb_bucket_override` be set to true if overriding"
  default     = ""
}

variable "lb_bucket_override" {
  description = "Override the default S3 bucket created for access logs with `lb_bucket`, defaults to false."
  default     = false
}

variable "lb_bucket_prefix" {
  description = "S3 bucket prefix for LB access logs."
  default     = ""
}

variable "lb_logs_enabled" {
  description = "S3 bucket LB access logs enabled, defaults to true."
  default     = true
}

variable "target_groups" {
  description = "List of target group ARNs to apply to the autoscaling group."
  type        = "list"
  default     = []
}

variable "users" {
  description = "Map of SSH users."

  default = {
    RHEL   = "ec2-user"
    Ubuntu = "ubuntu"
  }
}

variable "myapp_tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = "map"

  default = {
    "env" = "ppresto-mynginx"
  }
}

variable "myapp_tags_list" {
  description = "Optional list of tag maps to set on resources, defaults to empty list."
  type        = "list"
  default     = []
}
