resource "aws_db_instance" "default" {
  identifier                            = "shipping-${var.ENV}"
  allocated_storage                     = 20
  storage_type                          = "gp2"
  engine                                = "mysql"
  engine_version                        = "5.7"
  instance_class                        = "db.t2.micro"
  name                                  = "cities"
  username                              = "shipping"
  password                              = "secret123"
  parameter_group_name                  = "default.mysql5.7"
  db_subnet_group_name                  = aws_db_subnet_group.mysql.name
  vpc_security_group_ids                = [aws_security_group.allow-mysql.id]
  skip_final_snapshot                   = true
}

resource "aws_db_subnet_group" "mysql" {
  name                                  = "mysql"
  subnet_ids                            = data.terraform_remote_state.vpc.outputs.DB_SUBNETS

  tags = {
    Name                                = "mysql"
  }
}

resource "aws_security_group" "allow-mysql" {
  name                                    = "allow_mysql-${var.ENV}"
  description                             = "allow_mysql-${var.ENV}"
  vpc_id                                  = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                           = "DB"
    from_port                             = 3306
    to_port                               = 3306
    protocol                              = "tcp"
    cidr_blocks                           = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  egress {
    from_port                             = 0
    to_port                               = 0
    protocol                              = "-1"
    cidr_blocks                           = ["0.0.0.0/0"]
  }

  tags = {
    Name                                  = "allow_access_for_mysql"
  }
}

resource "null_resource" "mysql_apply" {
  provisioner "local-exec" {
    command = <<EOF
cd /tmp
rm -rf rs-mysql
git clone https://DevOps-Batches@dev.azure.com/DevOps-Batches/DevOps52/_git/rs-mysql
cd rs-mysql
mysql -h ${aws_db_instance.default.address} -u shipping -psecret123 <shipping.sql
EOF
  }
}

resource "aws_route53_record" "mysql" {
  name                                    = "mysql-${var.ENV}"
  type                                    = "CNAME"
  zone_id                                 = data.terraform_remote_state.vpc.outputs.INTERNAL_DOMAIN_ID
  ttl                                     = "300"
  records                                 = [aws_db_instance.default.address]
}
