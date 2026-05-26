
module "security-group" {
  source  = "terraform-aws-modules/security-group"
  version = "~> 5.3"

  name        = "nginx-sg"
  description = "Security group for Nginx instances"
  vpc_id      = module.vpc.vpc_id
  computed_egress_rules = "http-80-tcp"
}



module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "nginx-asg"

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  min_elb_capacity = 1 # TODO check if it creates the ELB
  health_check_type         = "ELB"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [
    module.security-group.security_group_id
  ]

  # initial_lifecycle_hooks = [
  #   {
  #     name                  = "ExampleStartupLifeCycleHook"
  #     default_result        = "CONTINUE"
  #     heartbeat_timeout     = 60
  #     lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
  #     notification_metadata = jsonencode({ "hello" = "world" })
  #   },
  #   {
  #     name                  = "ExampleTerminationLifeCycleHook"
  #     default_result        = "CONTINUE"
  #     heartbeat_timeout     = 180
  #     lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
  #     notification_metadata = jsonencode({ "goodbye" = "world" })
  #   }
  # ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
      max_healthy_percentage = 100
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = "nginx-asg"
  launch_template_description = "Nginx template"
  update_default_version      = true

  image_id          = "ami-037d7019a1e986dc5"  # TODO: use a correct AMI 2023
  instance_type     = "t3.micro"
  ebs_optimized     = true
  enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "nginx-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for Nginx ASG"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    }, {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash

    # TODO: test this
    yum update
    yum install nginx
  EOF
  )

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  cpu_options = {
    core_count       = 1
    threads_per_core = 1
  }

  credit_specification = {
    cpu_credits = "standard"
  }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = ["sg-12345678"]
    },
    {
      delete_on_termination = true
      description           = "eth1"
      device_index          = 1
      security_groups       = ["sg-12345678"]
    }
  ]

  placement = {
    availability_zone = "us-west-1b"
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = { WhatAmI = "Volume" }
    },
    {
      resource_type = "spot-instances-request"
      tags          = { WhatAmI = "SpotInstanceRequest" }
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "megasecret"
  }
}
