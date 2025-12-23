resource "aws_security_group" "app_sg" {
  name        = "blue-green-app-sg"
  description = "Allow HTTP & SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "blue-green-sg" }
}

resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-02b8269d5e85954ef"  # Amazon Linux 2
  instance_type = "m7i-flex.large"
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 8000:8000 ${var.docker_image}
              EOF

  tags = { Name = "blue-green-app-${count.index}" }
}
