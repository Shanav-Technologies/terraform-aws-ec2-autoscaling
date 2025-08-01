
# Terraform-aws-ec2-autoscaling

# Terraform AWS Cloud ec2-autoscaling Module

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Examples](#Examples)
- [Author](#Author)
- [License](#license)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction
This Terraform module creates an AWS load balancer (ec2-autoscaling) along with additional configuration options.
## Usage
To use this module, you can include it in your Terraform configuration. Here's an example of how to use it:

# Examples:

## Example: ec2-autoscaling

```hcl

  module "autoscaling" {
    source = "Shanav-Technologies/ec2-autoscaling/aws"
    version = "1.0.1"

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
```

## Example
For detailed examples on how to use this module, please refer to the '[example](https://github.com/Shanav-Technologies/terraform-aws-ec2-autoscaling/tree/master/example)' directory within this repository.

## Author
Your Name Replace **MIT** and **Shanav-Technologies** with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the **MIT** License - see the [LICENSE](https://github.com/Shanav-Technologies/terraform-aws-ec2-autoscaling/blob/master/LICENSE) file for details.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_labels"></a> [labels](#module\_labels) | git::https://github.com/Shanav-Technologies/terraform-aws-labels.git | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.idc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_schedule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_iam_instance_profile.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes (e.g. `1`). | `list(any)` | `[]` | no |
| <a name="input_autoscaling_group_tags"></a> [autoscaling\_group\_tags](#input\_autoscaling\_group\_tags) | A map of additional tags to add to the autoscaling group | `map(string)` | `{}` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | A list of one or more availability zones for the group. Used for EC2-Classic and default subnets when not specified with `vpc_zone_identifier` argument. Conflicts with `vpc_zone_identifier` | `list(string)` | `null` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | Specify volumes to attach to the instance besides the volumes specified by the AMI | `list(any)` | `[]` | no |
| <a name="input_capacity_rebalance"></a> [capacity\_rebalance](#input\_capacity\_rebalance) | Indicates whether capacity rebalance is enabled | `bool` | `null` | no |
| <a name="input_capacity_reservation_specification"></a> [capacity\_reservation\_specification](#input\_capacity\_reservation\_specification) | Targeting for EC2 capacity reservations | `any` | `{}` | no |
| <a name="input_cpu_options"></a> [cpu\_options](#input\_cpu\_options) | The CPU options for the instance | `map(string)` | `{}` | no |
| <a name="input_credit_specification"></a> [credit\_specification](#input\_credit\_specification) | Customize the credit specification of the instance | `map(string)` | `{}` | no |
| <a name="input_default_cooldown"></a> [default\_cooldown](#input\_default\_cooldown) | The amount of time, in seconds, after a scaling activity completes before another scaling activity can start | `number` | `null` | no |
| <a name="input_default_instance_warmup"></a> [default\_instance\_warmup](#input\_default\_instance\_warmup) | Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state. | `number` | `null` | no |
| <a name="input_default_version"></a> [default\_version](#input\_default\_version) | Default Version of the launch template | `string` | `null` | no |
| <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout) | Delete timeout to wait for destroying autoscaling group | `string` | `null` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the autoscaling group | `number` | `null` | no |
| <a name="input_desired_capacity_type"></a> [desired\_capacity\_type](#input\_desired\_capacity\_type) | The unit of measurement for the value specified for desired\_capacity. Supported for attribute-based instance type selection only. Valid values: `units`, `vcpu`, `memory-mib`. | `string` | `null` | no |
| <a name="input_disable_api_stop"></a> [disable\_api\_stop](#input\_disable\_api\_stop) | If true, enables EC2 instance stop protection | `bool` | `null` | no |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | If true, enables EC2 instance termination protection | `bool` | `null` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | If true, the launched EC2 instance will be EBS-optimized | `bool` | `null` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Determines whether to create autoscaling group or not | `bool` | `true` | no |
| <a name="input_enable_iam_instance_profile"></a> [enable\_iam\_instance\_profile](#input\_enable\_iam\_instance\_profile) | Determines whether an IAM instance profile is created or to use an existing IAM instance profile | `bool` | `false` | no |
| <a name="input_enable_launch_template"></a> [enable\_launch\_template](#input\_enable\_launch\_template) | Determines whether to create launch template or not | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enables/disables detailed monitoring | `bool` | `true` | no |
| <a name="input_enable_scaling_policy"></a> [enable\_scaling\_policy](#input\_enable\_scaling\_policy) | Determines whether to create target scaling policy schedule or not | `bool` | `true` | no |
| <a name="input_enable_schedule"></a> [enable\_schedule](#input\_enable\_schedule) | Determines whether to create autoscaling group schedule or not | `bool` | `true` | no |
| <a name="input_enabled_metrics"></a> [enabled\_metrics](#input\_enabled\_metrics) | A list of metrics to collect. The allowed values are `GroupDesiredCapacity`, `GroupInServiceCapacity`, `GroupPendingCapacity`, `GroupMinSize`, `GroupMaxSize`, `GroupInServiceInstances`, `GroupPendingInstances`, `GroupStandbyInstances`, `GroupStandbyCapacity`, `GroupTerminatingCapacity`, `GroupTerminatingInstances`, `GroupTotalCapacity`, `GroupTotalInstances` | `list(string)` | `[]` | no |
| <a name="input_enclave_options"></a> [enclave\_options](#input\_enclave\_options) | Enable Nitro Enclaves on launched instances | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate. You can force an Auto Scaling Group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling | `bool` | `null` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time (in seconds) after instance comes into service before checking health | `number` | `null` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | `EC2` or `ELB`. Controls how health checking is done | `string` | `null` | no |
| <a name="input_hibernation_options"></a> [hibernation\_options](#input\_hibernation\_options) | The hibernation options for the instance | `map(string)` | `{}` | no |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | Amazon Resource Name (ARN) of an existing IAM instance profile. Used when `create_iam_instance_profile` = `false` | `string` | `null` | no |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | The name of the IAM instance profile to be created (`create_iam_instance_profile` = `true`) or existing (`create_iam_instance_profile` = `false`) | `string` | `null` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_policies"></a> [iam\_role\_policies](#input\_iam\_role\_policies) | IAM policies to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_ignore_desired_capacity_changes"></a> [ignore\_desired\_capacity\_changes](#input\_ignore\_desired\_capacity\_changes) | Determines whether the `desired_capacity` value is ignored after initial apply. See README note for more details | `bool` | `false` | no |
| <a name="input_ignore_failed_scaling_activities"></a> [ignore\_failed\_scaling\_activities](#input\_ignore\_failed\_scaling\_activities) | Whether to ignore failed Auto Scaling scaling activities while waiting for capacity. The default is false -- failed scaling activities cause errors to be returned. | `bool` | `false` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | The AMI from which to launch the instance | `string` | `""` | no |
| <a name="input_initial_lifecycle_hooks"></a> [initial\_lifecycle\_hooks](#input\_initial\_lifecycle\_hooks) | One or more Lifecycle Hooks to attach to the Auto Scaling Group before instances are launched. The syntax is exactly the same as the separate `aws_autoscaling_lifecycle_hook` resource, without the `autoscaling_group_name` attribute. Please note that this will only work when creating a new Auto Scaling Group. For all other use-cases, please use `aws_autoscaling_lifecycle_hook` resource | `list(map(string))` | `[]` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | Shutdown behavior for the instance. Can be `stop` or `terminate`. (Default: `stop`) | `string` | `null` | no |
| <a name="input_instance_market_options"></a> [instance\_market\_options](#input\_instance\_market\_options) | The market (purchasing) option for the instance | `any` | `{}` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name that is propogated to launched EC2 instances via a tag - if not provided, defaults to `var.name` | `string` | `""` | no |
| <a name="input_instance_refresh"></a> [instance\_refresh](#input\_instance\_refresh) | If this block is configured, start an Instance Refresh when this Auto Scaling Group is updated | `any` | `{}` | no |
| <a name="input_instance_requirements"></a> [instance\_requirements](#input\_instance\_requirements) | The attribute requirements for the type of instance. If present then `instance_type` cannot be present | `any` | `{}` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The type of the instance. If present then `instance_requirements` cannot be present | `string` | `null` | no |
| <a name="input_kernel_id"></a> [kernel\_id](#input\_kernel\_id) | The kernel ID | `string` | `null` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The key name that should be used for the instance | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | Label order, e.g. `name`,`application`. | `list(any)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| <a name="input_launch_template_description"></a> [launch\_template\_description](#input\_launch\_template\_description) | Description of the launch template | `string` | `null` | no |
| <a name="input_launch_template_id"></a> [launch\_template\_id](#input\_launch\_template\_id) | ID of an existing launch template to be used (created outside of this module) | `string` | `null` | no |
| <a name="input_launch_template_use_name_prefix"></a> [launch\_template\_use\_name\_prefix](#input\_launch\_template\_use\_name\_prefix) | Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix | `bool` | `true` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version. Can be version number, `$Latest`, or `$Default` | `string` | `null` | no |
| <a name="input_license_specifications"></a> [license\_specifications](#input\_license\_specifications) | A list of license specifications to associate with | `map(string)` | `{}` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers. For ALBs, use `target_group_arns` instead | `list(string)` | `[]` | no |
| <a name="input_maintenance_options"></a> [maintenance\_options](#input\_maintenance\_options) | The maintenance options for the instance | `any` | `{}` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | ManagedBy, eg 'Shanav-Technologies'. | `string` | `"hello@Shanav-Technologies.com"` | no |
| <a name="input_max_instance_lifetime"></a> [max\_instance\_lifetime](#input\_max\_instance\_lifetime) | The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 86400 and 31536000 seconds | `number` | `null` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | The maximum size of the autoscaling group | `number` | `null` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Customize the metadata options for the instance | `map(string)` | `{}` | no |
| <a name="input_metrics_granularity"></a> [metrics\_granularity](#input\_metrics\_granularity) | The granularity to associate with the metrics to collect. The only valid value is `1Minute` | `string` | `null` | no |
| <a name="input_min_elb_capacity"></a> [min\_elb\_capacity](#input\_min\_elb\_capacity) | Setting this causes Terraform to wait for this number of instances to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes | `number` | `null` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | The minimum size of the autoscaling group | `number` | `null` | no |
| <a name="input_mixed_instances_policy"></a> [mixed\_instances\_policy](#input\_mixed\_instances\_policy) | Configuration block containing settings to define launch targets for Auto Scaling groups | `any` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Customize network interfaces to be attached at instance boot time | `list(any)` | `[]` | no |
| <a name="input_placement"></a> [placement](#input\_placement) | The placement of the instance | `map(string)` | `{}` | no |
| <a name="input_placement_group"></a> [placement\_group](#input\_placement\_group) | The name of the placement group into which you'll launch your instances, if any | `string` | `null` | no |
| <a name="input_private_dns_name_options"></a> [private\_dns\_name\_options](#input\_private\_dns\_name\_options) | The options for the instance hostname. The default values are inherited from the subnet | `map(string)` | `{}` | no |
| <a name="input_protect_from_scale_in"></a> [protect\_from\_scale\_in](#input\_protect\_from\_scale\_in) | Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events. | `bool` | `false` | no |
| <a name="input_ram_disk_id"></a> [ram\_disk\_id](#input\_ram\_disk\_id) | The ID of the ram disk | `string` | `null` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Terraform current module repo | `string` | `"https://github.com/Shanav-Technologies/terraform-aws-ec2-autoscaling"` | no |
| <a name="input_scaling_policies"></a> [scaling\_policies](#input\_scaling\_policies) | Map of target scaling policy schedule to create | `any` | `{}` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Map of autoscaling group schedule to create | `map(any)` | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | A list of security group IDs to associate | `list(string)` | `[]` | no |
| <a name="input_service_linked_role_arn"></a> [service\_linked\_role\_arn](#input\_service\_linked\_role\_arn) | The ARN of the service-linked role that the ASG will use to call other AWS services | `string` | `null` | no |
| <a name="input_suspended_processes"></a> [suspended\_processes](#input\_suspended\_processes) | A list of processes to suspend for the Auto Scaling Group. The allowed values are `Launch`, `Terminate`, `HealthCheck`, `ReplaceUnhealthy`, `AZRebalance`, `AlarmNotification`, `ScheduledActions`, `AddToLoadBalancer`, `InstanceRefresh`. Note that if you suspend either the `Launch` or `Terminate` process types, it can prevent your Auto Scaling Group from functioning properly | `list(string)` | `[]` | no |
| <a name="input_tag_specifications"></a> [tag\_specifications](#input\_tag\_specifications) | The tags to apply to the resources during launch | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources | `map(string)` | `{}` | no |
| <a name="input_target_group_arns"></a> [target\_group\_arns](#input\_target\_group\_arns) | A set of `aws_alb_target_group` ARNs, for use with Application or Network Load Balancing | `list(string)` | `[]` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | A list of policies to decide how the instances in the Auto Scaling Group should be terminated. The allowed values are `OldestInstance`, `NewestInstance`, `OldestLaunchConfiguration`, `ClosestToNextInstanceHour`, `OldestLaunchTemplate`, `AllocationStrategy`, `Default` | `list(string)` | `[]` | no |
| <a name="input_update_default_version"></a> [update\_default\_version](#input\_update\_default\_version) | Whether to update Default Version each update. Conflicts with `default_version` | `string` | `null` | no |
| <a name="input_use_mixed_instances_policy"></a> [use\_mixed\_instances\_policy](#input\_use\_mixed\_instances\_policy) | Determines whether to use a mixed instances policy in the autoscaling group or not | `bool` | `false` | no |
| <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix) | Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix | `bool` | `true` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | The Base64-encoded user data to provide when launching the instance | `string` | `null` | no |
| <a name="input_vpc_zone_identifier"></a> [vpc\_zone\_identifier](#input\_vpc\_zone\_identifier) | A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside. Conflicts with `availability_zones` | `list(string)` | `null` | no |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior. | `string` | `null` | no |
| <a name="input_wait_for_elb_capacity"></a> [wait\_for\_elb\_capacity](#input\_wait\_for\_elb\_capacity) | Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations. Takes precedence over `min_elb_capacity` behavior. | `number` | `null` | no |
| <a name="input_warm_pool"></a> [warm\_pool](#input\_warm\_pool) | If this block is configured, add a Warm Pool to the specified Auto Scaling group | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The ARN for main AutoScaling Group |
| <a name="output_autoscaling_group_availability_zones"></a> [autoscaling\_group\_availability\_zones](#output\_autoscaling\_group\_availability\_zones) | The availability zones of the autoscale group |
| <a name="output_autoscaling_group_default_cooldown"></a> [autoscaling\_group\_default\_cooldown](#output\_autoscaling\_group\_default\_cooldown) | Time between a scaling activity and the succeeding scaling activity |
| <a name="output_autoscaling_group_desired_capacity"></a> [autoscaling\_group\_desired\_capacity](#output\_autoscaling\_group\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group |
| <a name="output_autoscaling_group_enabled_metrics"></a> [autoscaling\_group\_enabled\_metrics](#output\_autoscaling\_group\_enabled\_metrics) | List of metrics enabled for collection |
| <a name="output_autoscaling_group_health_check_grace_period"></a> [autoscaling\_group\_health\_check\_grace\_period](#output\_autoscaling\_group\_health\_check\_grace\_period) | Time after instance comes into service before checking health |
| <a name="output_autoscaling_group_health_check_type"></a> [autoscaling\_group\_health\_check\_type](#output\_autoscaling\_group\_health\_check\_type) | EC2 or ELB. Controls how health checking is done |
| <a name="output_autoscaling_group_id"></a> [autoscaling\_group\_id](#output\_autoscaling\_group\_id) | The autoscaling group id |
| <a name="output_autoscaling_group_load_balancers"></a> [autoscaling\_group\_load\_balancers](#output\_autoscaling\_group\_load\_balancers) | The load balancer names associated with the autoscaling group |
| <a name="output_autoscaling_group_max_size"></a> [autoscaling\_group\_max\_size](#output\_autoscaling\_group\_max\_size) | The maximum size of the autoscale group |
| <a name="output_autoscaling_group_min_size"></a> [autoscaling\_group\_min\_size](#output\_autoscaling\_group\_min\_size) | The minimum size of the autoscale group |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | The autoscaling group name |
| <a name="output_autoscaling_group_target_group_arns"></a> [autoscaling\_group\_target\_group\_arns](#output\_autoscaling\_group\_target\_group\_arns) | List of Target Group ARNs that apply to main AutoScaling Group |
| <a name="output_autoscaling_group_vpc_zone_identifier"></a> [autoscaling\_group\_vpc\_zone\_identifier](#output\_autoscaling\_group\_vpc\_zone\_identifier) | The VPC zone identifier |
| <a name="output_autoscaling_policy_arns"></a> [autoscaling\_policy\_arns](#output\_autoscaling\_policy\_arns) | ARNs of autoscaling policies |
| <a name="output_autoscaling_schedule_arns"></a> [autoscaling\_schedule\_arns](#output\_autoscaling\_schedule\_arns) | ARNs of autoscaling group schedules |
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | ARN assigned by AWS to the instance profile |
| <a name="output_iam_instance_profile_id"></a> [iam\_instance\_profile\_id](#output\_iam\_instance\_profile\_id) | Instance profile's ID |
| <a name="output_iam_instance_profile_unique"></a> [iam\_instance\_profile\_unique](#output\_iam\_instance\_profile\_unique) | Stable and unique string identifying the IAM instance profile |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role |
| <a name="output_iam_role_unique_id"></a> [iam\_role\_unique\_id](#output\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | The ARN of the launch template |
| <a name="output_launch_template_default_version"></a> [launch\_template\_default\_version](#output\_launch\_template\_default\_version) | The default version of the launch template |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | The ID of the launch template |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | The latest version of the launch template |
| <a name="output_launch_template_name"></a> [launch\_template\_name](#output\_launch\_template\_name) | The name of the launch template |
<!-- END_TF_DOCS -->
