resource "aws_elasticache_cluster" "redis" {
  cluster_id                            = "redis-${var.ENV}"
  engine                                = "redis"
  node_type                             = "cache.t3.small"
  num_cache_nodes                       = 1
  parameter_group_name                  = "default.redis3.2"
  engine_version                        = "3.2.10"
  port                                  = 6379
  subnet_group_name                     = aws_elasticache_subnet_group.redis.name
  security_group_ids                    = [aws_security_group.allow-redis.id]

}

resource "aws_elasticache_subnet_group" "redis" {
  name                                  = "redis"
  subnet_ids                            = data.terraform_remote_state.vpc.outputs.DB_SUBNETS
}

resource "aws_security_group" "allow-redis" {
  name                                    = "allow_redis-${var.ENV}"
  description                             = "allow_redis-${var.ENV}"
  vpc_id                                  = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                           = "DB"
    from_port                             = 6379
    to_port                               = 6379
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
    Name                                  = "allow_redis"
  }
}

resource "aws_route53_record" "redis" {
  name                                    = "redis-${var.ENV}"
  type                                    = "CNAME"
  zone_id                                 = data.terraform_remote_state.vpc.outputs.INTERNAL_DOMAIN_ID
  ttl                                     = "300"
  records                                 = [aws_elasticache_cluster.redis.cache_nodes.0.address]
}