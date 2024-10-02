# -------------------- RESOURCES --------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-vpc"
  cidr = local.vpc_cidr_range

  azs             = local.azs
  private_subnets = local.private_subnets_cidrs
  public_subnets  = local.public_subnets_cidrs

  single_nat_gateway  = false
  enable_nat_gateway = true
  enable_vpn_gateway = false
}

resource "aws_ecr_repository" "this" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.project_name}-${var.environment}-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    (var.project_name) = {
      cpu    = 1024
      memory = 4096

      container_definitions = {
        (var.project_name) = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${aws_ecr_repository.this.repository_url}:latest"
          port_mappings = [
            {
              name          = var.project_name
              containerPort = var.app_port
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem = false
          memory_reservation = 100
          enable_cloudwatch_logging = true
        }
      }

      load_balancer = {
        service = {
          target_group_arn = "${aws_lb_target_group.target_group.arn}"
          container_name   = var.project_name
          container_port   = var.app_port
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = var.app_port
          to_port                  = var.app_port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = aws_security_group.alb.id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}

// ALB
resource "aws_alb" "this" {
  name                = "${var.project_name}-${var.environment}"
  load_balancer_type  = "application"
  subnets             = module.vpc.public_subnets
  security_groups     = ["${aws_security_group.alb.id}"]
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path = "/healthcheck"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_alb.this.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// ALB Security group
resource "aws_security_group" "alb" {
  name        = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# -------------------- LOCALS --------------------
locals {
  azs             = data.aws_availability_zones.available.zone_ids
  vpc_cidr_range  =  "10.0.0.0/16"
  private_subnets_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
