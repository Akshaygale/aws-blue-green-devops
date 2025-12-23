resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "blue-green-vpc" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = { Name = "public-subnet-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index+2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = { Name = "private-subnet-${count.index}" }
}
