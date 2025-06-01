# --------------------------------
# Security Group
# --------------------------------
# App
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-${var.env}-app-sg"
  description = "Application Security Group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name        = "${var.project}-${var.env}-app-sg"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_security_group_rule" "app_sg_in3000" {
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_sg_in443" {
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_sg_in22" {
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_sg_out" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_out_tcp3306" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.db_sg.id
}

# DB
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-${var.env}-db-sg"
  description = "Database Security Group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name        = "${var.project}-${var.env}-db-sg"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_security_group_rule" "db_sg_in3306" {
  security_group_id        = aws_security_group.db_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.app_sg.id
}

#operation
resource "aws_security_group" "opmng_sg" {
  name        = "${var.project}-${var.env}-opmng-sg"
  description = "operation and management role security groupe"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = "${var.project}-${var.env}-opmng-sg"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_security_group_rule" "opmng_in_ssh" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "opmng_in_tcp3000" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "opmng_out_http" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "opmng_out_https" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
