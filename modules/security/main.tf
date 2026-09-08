resource "aws_security_group" "web" {
  # checkov:skip=CKV_AWS_260:Web layer must accept HTTP/HTTPS from the internet by design
  # checkov:skip=CKV2_AWS_5:No EC2 resources in this stage; SG will be attached later
  name        = "${var.name_prefix}-web-sg"
  description = "Web layer: internetdan HTTP va HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-web-sg"
  }
}

resource "aws_security_group" "application" {
  # checkov:skip=CKV2_AWS_5:No EC2 resources in this stage; SG will be attached later
  name        = "${var.name_prefix}-app-sg"
  description = "Application layer: faqat web layer dan kelgan trafik"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application traffic from web layer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }
}

# Database security group keyingi bosqichda qo'shiladi:
# ingress faqat application SG dan, DB porti uchun (masalan PostgreSQL 5432).
