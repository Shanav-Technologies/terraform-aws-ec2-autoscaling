provider "aws" {
  region = local.region
}

locals {
  name        = "app"
  environment = "test"
  region      = "ca-central-1"


  # user_data = <<-EOT
  #   #!/bin/bash
  #   echo "Hello Terraform!"
  # EOT
}


module "vpc" {
  source      = "git::https://github.com/Shanav-Technologies/terraform-aws-vpc.git?ref=v1.0.0"
  name        = local.name
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}

module "subnets" {
  source              = "git::https://github.com/Shanav-Technologies/terraform-aws-subnet.git?ref=v1.0.0"
  nat_gateway_enabled = true
  single_nat_gateway  = true
  availability_zones  = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
  vpc_id              = module.vpc.id
  type                = "public-private"
  igw_id              = module.vpc.igw_id
  cidr_block          = module.vpc.vpc_cidr_block
}


module "security_group" {
  source      = "git::https://github.com/Shanav-Technologies/terraform-aws-security-group.git?ref=v1.0.0"
  name        = local.name
  environment = local.environment
  vpc_id      = module.vpc.id

  ## INGRESS Rules
  new_sg_ingress_rules_with_cidr_blocks = [{
    rule_count  = 1
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http traffic."
    },

  ]

  ## EGRESS Rules
  new_sg_egress_rules_with_cidr_blocks = [{
    rule_count  = 1
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow  outbound traffic."
    }

  ]
}

################################################################################
# Complete
################################################################################

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "autoscaling" {
  source = "./../"

  #Launch template
  for_each = {
    # On-demand instances
    ex-1 = {
      instance_type              = "t3.large"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.name)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
    # Spot instances
    ex-2 = {
      instance_type              = "t3.medium"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          {
            instance_type     = "m4.large"
            weighted_capacity = "2"
          },
          {
            instance_type     = "t3.large"
            weighted_capacity = "1"
          },
        ]
      }
      user_data = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.name)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
        EOF
      EOT
    }
  }

  name = "${local.name}-${each.key}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [module.security_group.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  enable_iam_instance_profile = true
  iam_role_name               = local.name
  iam_role_description        = "ECS role for ${local.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = [module.subnets.public_subnet_id[0], module.subnets.public_subnet_id[1], module.subnets.public_subnet_id[2]]
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

}