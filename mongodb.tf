resource "aws_instance" "mongodb" {
  ami                                     = data.aws_ami.ami.id
  instance_type                           = "t3.micro"
  subnet_id                               = data.terraform_remote_state.vpc.outputs.DB_SUBNETS[0]
  vpc_security_group_ids                  = [aws_security_group.allow-mongodb.id]
  tags = {
                Name                      = "mongodb"
  }
}

resource "aws_security_group" "allow-mongodb" {
  name                                    = "allow_mongodb-${var.ENV}"
  description                             = "allow_mongodb-${var.ENV}"
  vpc_id                                  = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                           = "SSH"
    from_port                             = 22
    to_port                               = 22
    protocol                              = "tcp"
    cidr_blocks                           = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description                           = "DB"
    from_port                             = 27017
    to_port                               = 27017
    protocol                              = "tcp"
    cidr_blocks                           = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port                             = 0
    to_port                               = 0
    protocol                              = "-1"
    cidr_blocks                           = ["0.0.0.0/0"]
  }

  tags = {
    Name                                  = "allow_access_for_${var.ENV}"
  }
}

resource "null_resource" "ansible" {
  provisioner "remote-exec" {
    connection {
      host                                = aws_instance.mongodb.private_ip
      user                                = "centos"
      password                            = "DevOps321"
    }

    inline                                = [
      "sudo yum install ansible -y",
      "ansible-pull -i localhost, -U https://DevOps-Batches@dev.azure.com/DevOps-Batches/DevOps52/_git/ansible roboshop.yml -t mongo -e component=mongo -e PAT=z3era56q3lxk4omg42ac2lklc7ys2mwjbjxqvey5wjmzxgs2gloq -e ENV=${var.ENV} -e ELASTICSEARCH=172.31.68.240"
    ]
  }
}

resource "aws_route53_record" "mongodb" {
  name                                    = "mongo-${var.ENV}"
  type                                    = "A"
  zone_id                                 = data.terraform_remote_state.vpc.outputs.INTERNAL_DOMAIN_ID
  ttl                                     = "300"
  records                                 = [aws_instance.mongodb.private_ip]
}
