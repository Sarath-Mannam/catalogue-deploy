module "catalogue_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_ami.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value), 0)
  iam_instance_profile = "catalogue_profile"
  //user_data = file("catalogue.sh")
  tags = merge(
    {
        Name = "Catalogue-DEV-AMI"
    },
    var.common_tags
  )
}

resource "null_resource" "cluster" {
 
  triggers = {
    instance_id = module.catalogue_instance.id
  }
  connection { # post instance creation it will establish a connection using connection block
    type = "ssh"
    user = "centos"
    password = "DevOps321"
    host = module.catalogue_instance.private_ip
  }
  # copy the file 
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",  // give the execute permission
      "sudo sh /tmp/catalogue.sh ${var.app_version}"    // runs the catalogue script 
    ]
  }
}

# stop instance for taking AMI
resource "aws_ec2_instance_state" "catalogue_instance" {
  instance_id = module.catalogue_instance.id
  state = "stopped"
  depends_on = [ null_resource.cluster ]
}

resource "aws_ami_from_instance" "catalogue_ami" {
  name = "${var.common_tags.Component}-${local.current_time}"
  source_instance_id = module.catalogue_instance.id
  depends_on = [ aws_ec2_instance_state.catalogue_instance ]
}

resource "null_resource" "delete_instance" {
  
  triggers = {
    ami_id = aws_ami_from_instance.catalogue_ami.id
  }
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.catalogue_instance.id}"
  }
  depends_on = [ aws_ami_from_instance.catalogue_ami ]
}

resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project_name}-${var.common_tags.Component}-${var.env}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  deregistration_delay = 60
  health_check {
    enabled = true
    healthy_threshold = 2 # Continuously two health checks are success then you can consider as healthy
    interval = 15 # For every 15 seconds will check health of the component
    matcher = "200-299" # Any response code within this range consider it as success
    path = "/health" # will get the response if component is healthy
    port = 8080
    protocol = "HTTP"
    timeout = 5 # if there is no response within 5 seconds then consider it as failure
    unhealthy_threshold = 3 # If three consecutive requests are failed then consider as failure
  }
}

resource "aws_launch_template" "catalogue" {
  name = "${var.project_name}-${var.common_tags.Component}-${var.env}"
  image_id = aws_ami_from_instance.catalogue_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Catalogue"
    }
  }

  # user_data = filebase64("${path.module}/catalogue.sh") # Convert text into base64-encoded user data to provide when launching the instance
  # here we don't need since we have already configured AMI Completely
}

resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project_name}-${var.common_tags.Component}-${var.env}-${local.current_time}}"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB" # Load balancer responsibility is to check health of instances
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.catalogue.arn] # Target Group
  launch_template {
    id      = aws_launch_template.catalogue.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  tag {
    key                 = "Name"
    value               = "Catalogue"
    propagate_at_launch = true
  }
  timeouts {
    delete = "15m"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "catalogue" {
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name = "cpu"
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      values = ["${var.common_tags.Component}.app-${var.env}.${var.domain_name}"]
    }
  }
  # When you receive request from the above host header then forward request to the catalogue group
}

output "app_version" {
  value = var.app_version
}

