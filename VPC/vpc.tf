resource "aws_vpc" "apci_main_vpc" {
  cidr_block = var.vpc_cidr_block

    tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.apci_main_vpc.id

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-igw"
  })
}

# Creating Frontend subnet==========================================================

resource "aws_subnet" "frontend_subnet_az2a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.frontend_cidr_block[0]
  availability_zone = var.availability_zone[0]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-frontend-subnet-az1a"
  })
}

resource "aws_subnet" "frontend_subnet_az2b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.frontend_cidr_block[1]
  availability_zone = var.availability_zone[1]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-frontend-subnet-az2b"
  })
}

# Creating backend subnet===============================================================

resource "aws_subnet" "backend_subnet_az2a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[0]
  availability_zone = var.availability_zone[0]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-backend-subnet-az2a"
  })
}

resource "aws_subnet" "backend_subnet_az2b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[1]
  availability_zone = var.availability_zone[1]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-backend-subnet-az2b"
  })
}

#Creating DB subnet===================================================================

resource "aws_subnet" "db_subnet_az2a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[2]
  availability_zone = var.availability_zone[0]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-db-subnet-az2a"
  })
}

resource "aws_subnet" "db_subnet_az2b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[3]
  availability_zone = var.availability_zone[1]

   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-db-subnet-az2b"
  })
}

# Creating public route table=====================================================

resource "aws_route_table" "apci_public_rt" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-public_rt"
  })
}

#Creating route table association==========================================================

resource "aws_route_table_association" "frontend_subnet_az2a" {
  subnet_id      = aws_subnet.frontend_subnet_az2a.id
  route_table_id = aws_route_table.apci_public_rt.id
}

resource "aws_route_table_association" "frontend_subnet_az2b" {
  subnet_id      = aws_subnet.frontend_subnet_az2b.id
  route_table_id = aws_route_table.apci_public_rt.id
}

# Crearting  an elastic IP for NAT gateway==================================================

resource "aws_eip" "eip" {
  domain   = "vpc"
  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-eip"
  }) 
}

# Creating Nat gateway=======================================

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.frontend_subnet_az2a.id

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-nat-gw"
  }) 

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_eip.eip, aws_subnet.frontend_subnet_az2a]
}

# Creating a Private route table========================================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-private_rt"
  })
}

# Creating Route table assoaciation for backend subnet================================

resource "aws_route_table_association" "backend_subnet_az2a" {
  subnet_id      = aws_subnet.backend_subnet_az2a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_subnet_az2a" {
  subnet_id      = aws_subnet.db_subnet_az2a.id
  route_table_id = aws_route_table.private_rt.id
}

#Creating elastic IP for Availability Zone 2b==========================

resource "aws_eip" "eip_az2b" {
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-eip-az2b"
  }) 
}

#Creating NAT gateway for AZ 2b===================================================================

resource "aws_nat_gateway" "nat_gw_AZ2b" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.frontend_subnet_az2b.id

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-nat-gw-az2b"
  }) 

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_eip.eip_az2b, aws_subnet.frontend_subnet_az2b]
}

#Creating private routable for AZ 2b==================================================================

resource "aws_route_table" "private_rt_az2b" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_AZ2b.id
  }

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-private-rt-az2b"
  })
}

#Creating route table assosciation for backend subnet in AZ 2b
resource "aws_route_table_association" "backend_subnet_az2b" {
  subnet_id      = aws_subnet.backend_subnet_az2b.id
  route_table_id = aws_route_table.private_rt_az2b.id
}

resource "aws_route_table_association" "db_subnet_az2b" {
  subnet_id      = aws_subnet.db_subnet_az2b.id
  route_table_id = aws_route_table.private_rt_az2b.id
}