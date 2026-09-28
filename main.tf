# 1. Automatically fetch the default VPC (simplifies testing)
data "aws_vpc" "default" {
  default = true
}

# 2. Fetch a public subnet in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 3. Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 4. Generate a new RSA private key
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 5. Register the public key with AWS EC2
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# 6. Save the private key locally
resource "local_file" "private_key_pem" {
  content         = tls_private_key.rsa_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

# 7. Create security group restricting SSH to 70.130.70.1
resource "aws_security_group" "instance_sg" {
  name        = "terraform-ec2-restricted-sg"
  description = "Security group allowing SSH only from a specific IP"
  vpc_id      = data.aws_vpc.default.id

  # Inbound rule: Allow SSH (Port 22) ONLY from your IP
  ingress {
    description = "Allow SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["70.130.72.11/32"]
  }

  # Outbound rule: Allow all outbound traffic so the instance can reach the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. Provision the EC2 instance
resource "aws_instance" "test_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = "Terraform-Secured-Instance"
  }
}
