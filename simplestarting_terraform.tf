# Configure the AWS Provider
provider "aws" {
    region  = "us-east-1"
    access_key = ""
    secret_key = ""
}

#resource "<provider_resource_type>" "name" {
#   config option....
#   key1 = "value1" 
#   key2 = "value2"
#}

#DEPLOYING EC2 INSTANCE - FIRST LEARN MANUALLY

resource "aws_instance" "web_aws_not_aware_of_this_name" {
    ami           = ""
    instance_type = "t2.micro"
    tags = {
        Name = "Machine Mayuri"
    }
}

#TO RUN
#terrform init
#terraform plan
#terraform apply
#terraform destroy

#CREATE VPC - cidr block is important

resource "aws_vpc" "vpc1" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

#CREATE SUBNET 

resource "aws_subnet" "subnet1" {
  #vpc_id     = we want to reference the vpc which we are creating bcz its not already created
  vpc_id = aws_vpc.vpc1.id
  
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Productionsubnet"
  }
}

#terraform doeesnt worry about what shoult be written first it knows what should be created first


#PROJECT
#create vpc
#create internet gateway
#create a custom route table 
#create a subnet 
#associate subnet with route table
#create security groups to allow port 22,80,443
#create network interface with an ip in subnet that was created in step4
#assign an elastic ip to the network interface created in step 7
#create ubuntu server and install apache2

#create vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

#create a custom route table 
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0" #this means all traffic is going to be send to internet gateway
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example"
  }
}

#create a subnet 
resource "aws_subnet" "subnet1" {
  #vpc_id     = we want to reference the vpc which we are creating bcz its not already created
  vpc_id = aws_vpc.vpc1.id
  
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  tags = {
    Name = "Productionsubnet"
  }
}

#associate subnet with route table - route table association is used 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.example.id
}

#create security groups to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "allow the web traffic"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name = "allow_web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # all ports
}

#create network interface with an ip in subnet that was created in step4
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#assign an elastic ip to the network interface created in step 7
resource "aws_eip" "lb" {
  instance = aws_instance.web.id
  domain   = "vpc"
  depends_on = ["internet_gateway.gw"] #we want to consider whole object not just the id #depends on used with list type brakets
}
#create ubuntu server and install apache2
resource "aws_instance" "web_server" {
    ami = ""
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"#subnet is created in this 
    key_name = "name of the key"

}

#TERRAFORM COMMANDS
#terraform state - manage state of terraform shows subcommands
#terraform state list - list all the resources
#terraform state show <any resource> - shows the details of the resource
