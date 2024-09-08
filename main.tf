resource "aws_vpc" "test-project" {
  cidr_block       = var.cidr_block_vpc
  instance_tenancy = "default"

  tags = {
    Name = "test-project"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.test-project.id
  cidr_block              = var.cidr_block_subnet1
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.test-project.id
  cidr_block              = var.cidr_block_subnet2
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test-project.id

  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.test-project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt"
  }
}

resource "aws_route_table_association" "rtas1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rtas2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "my_sg" {
  name        = "websg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.test-project.id

  tags = {
    Name = "websg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.my_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.my_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.my_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_s3_bucket" "test-project" {
  bucket = "test-project-sreekanthv.com"

  tags = {
    Name = "test-project"
  }
}

resource "aws_instance" "web-server-1" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  user_data              = base64encode(file("userdata.sh"))
  tags = {
    Name = "web-server-1"
  }
}

resource "aws_instance" "web-server-2" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  user_data              = base64encode(file("userdata1.sh"))

  tags = {
    Name = "web-server-2"
  }
}

resource "aws_lb" "test-project" {
  name               = "test-project-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Environment = "test-project-lb"
  }
}

resource "aws_lb_target_group" "test-project" {
  name     = "test-project-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test-project.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "test-project_target1" {
  target_group_arn = aws_lb_target_group.test-project.arn
  target_id        = aws_instance.web-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test-project-target2" {
  target_group_arn = aws_lb_target_group.test-project.arn
  target_id        = aws_instance.web-server-2.id
  port             = 80
}

resource "aws_lb_listener" "lb-test-project" {
  load_balancer_arn = aws_lb.test-project.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-project.arn
  }
}