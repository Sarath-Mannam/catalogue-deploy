module "catalogue_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_ami.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id = split(data.aws_ssm_parameter.private_subnet_ids,0)
  //user_data = file("catalogue.sh")
  tags = merge(
    {
        Name = "Catalogue-DEV-AMI"
    },
    var.common_tags
  )
}