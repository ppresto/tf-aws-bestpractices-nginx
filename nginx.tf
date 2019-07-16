data "template_file" "myapp_user_data" {
  # user_data        = "${data.template_file.myapp_user_data.rendered}"
  count    = "${var.myapp_create ? 1 : 0}"
  template = "${file("${path.module}/templates/ubuntu-16-nginx-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    provider     = "${var.provider}"
    local_ip_url = "${var.local_ip_url}"
    packages     = "${var.install_packages}"
    port         = "${var.nginx_httpport}"
    ca_crt       = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt     = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key     = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  }
}

terraform {
  required_version = ">= 0.11.5"
}

# https://www.consul.io/docs/agent/options.html#ports
module "security_groups_aws" {
  source      = "github.com/hashicorp-modules/consul-client-ports-aws"
  create      = "${var.myapp_create ? 1 : 0}"
  name        = "${var.name}-myapp-server"
  vpc_id      = "${module.network_aws.vpc_id}"
  cidr_blocks = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]   # If there's a public IP, open Consul ports for public access - DO NOT DO THIS IN PROD
  tags        = "${var.myapp_tags}"
}

# SSH - 22
resource "aws_security_group_rule" "ssh" {
  count = "${var.myapp_create ? 1 : 0}"

  security_group_id = "${module.security_groups_aws.consul_client_sg_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]
}

#HTTP
resource "aws_security_group_rule" "myapp_httpport" {
  count = "${var.myapp_create ? 1 : 0}"

  security_group_id = "${module.security_groups_aws.consul_client_sg_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "${var.nginx_httpport}"
  to_port           = "${var.nginx_httpport}"
  cidr_blocks       = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]
}

#TCP Port Range
resource "aws_security_group_rule" "myapp_portrange" {
  count = "${var.myapp_create ? 1 : 0}"

  security_group_id = "${module.security_groups_aws.consul_client_sg_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8090
  cidr_blocks       = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]
}

# HTTPS Port
resource "aws_security_group_rule" "myapp_https" {
  count = "${var.myapp_create ? 1 : 0}"

  security_group_id = "${module.security_groups_aws.consul_client_sg_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]
}

data "aws_ami" "myapp" {
  count       = "${var.myapp_create && var.myapp_image_id == "" ? 1 : 0}"
  most_recent = true
  owners      = ["${var.myapp_ami_owner}"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "myapp" {
  count         = "${var.myapp_create ? 1 : 0}"
  name_prefix   = "${format("%s-myapp-", var.name)}"
  image_id      = "${data.aws_ami.myapp.id}"
  instance_type = "${var.myapp_instance_type}"
  key_name      = "${module.ssh_keypair_aws_override.name}"
  user_data     = "${data.template_file.myapp_user_data.rendered}"

  security_groups = [
    "${module.security_groups_aws.consul_client_sg_id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

module "myapp_lb_aws" {
  #source = "github.com/hashicorp-modules/consul-lb-aws"
  #source = "../aws-lb"
  #source = "../../tf_module_aws_lb"
  source = "github.com/ppresto/tf_module_aws_lb"

  create             = "${var.myapp_create}"
  name               = "${var.name}"
  vpc_id             = "${module.network_aws.vpc_id}"
  cidr_blocks        = ["${var.myapp_public ? "0.0.0.0/0" : var.vpc_cidr}"]                                                                                     # If there's a public IP, open port 22 for public access - DO NOT DO THIS IN PROD
  subnet_ids         = ["${split(",", var.myapp_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"]
  is_internal_lb     = "${!var.myapp_public}"
  use_lb_cert        = "${var.use_lb_cert}"
  lb_cert            = "${var.lb_cert}"
  lb_private_key     = "${var.lb_private_key}"
  lb_cert_chain      = "${var.lb_cert_chain}"
  lb_ssl_policy      = "${var.lb_ssl_policy}"
  lb_bucket          = "${var.lb_bucket}"
  lb_bucket_override = "${var.lb_bucket_override}"
  lb_bucket_prefix   = "${var.lb_bucket_prefix}"
  lb_logs_enabled    = "${var.lb_logs_enabled}"
  tags               = "${var.myapp_tags}"
}

resource "aws_autoscaling_group" "myapp" {
  count = "${var.myapp_create ? 1 : 0}"

  name_prefix          = "${aws_launch_configuration.myapp.name}"
  launch_configuration = "${aws_launch_configuration.myapp.id}"
  vpc_zone_identifier  = ["${split(",", var.myapp_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"]
  max_size             = "${var.myapp_count != -1 ? var.myapp_count : length("${split(",", var.myapp_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}")}"
  min_size             = "${var.myapp_count != -1 ? var.myapp_count : length("${split(",", var.myapp_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}")}"
  desired_capacity     = "${var.myapp_count != -1 ? var.myapp_count : length("${split(",", var.myapp_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}")}"
  default_cooldown     = 30
  force_delete         = true

  target_group_arns = ["${compact(concat(
    list(
      module.myapp_lb_aws.myapp_tg_http_80_arn,
    ),
    var.target_groups
  ))}"]

  tags = ["${concat(
    list(
      map("key", "Name", "value", format("%s-myapp-node", var.name), "propagate_at_launch", true),
      map("key", "Consul-Auto-Join", "value", var.name, "propagate_at_launch", true)
    ),
    var.myapp_tags_list
  )}"]

  lifecycle {
    create_before_destroy = true
  }
}
