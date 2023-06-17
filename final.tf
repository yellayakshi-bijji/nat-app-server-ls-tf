terraform{
    required_providers{
        aws={
            source ="hashicorp/aws"
            version = "5.0.1"
        }
    }
}

#creating vpc
resource "aws_vpc" "vpc"{
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "vpc_tf"
    }
}

#creating an Internet Gateway
resource "aws_internet_gateway" "igw"{
    depends_on = [
        aws_vpc.vpc,
        ]
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "internetGateway_tf"
    }
}

#resource "aws_internet_gateway_attachment" "igw_attachment" {  #############################added by rithvik
#  internet_gateway_id = aws_internet_gateway.igw.id
#  vpc_id              = aws_vpc.vpc.id
#}

#creating a public route
resource "aws_route_table" "publicrt"{
    depends_on = [
        aws_vpc.vpc,
        aws_internet_gateway.igw,
        ]
    vpc_id = aws_vpc.vpc.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "publicroute_tf"
    }
}

#creating a private route
resource "aws_route_table" "privatert"{
    depends_on = [
        aws_vpc.vpc,
        aws_instance.natinstance,
    ]                       ########################################## removed route by rithvik

    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "privateroute_tf"
    }
}

#Associating Routetable with Public Subnet
resource "aws_route_table_association" "publicrtassociation"{
    depends_on = [
        aws_subnet.publicsubnet,
        aws_route_table.publicrt,
        ]
    subnet_id = aws_subnet.publicsubnet.id
    route_table_id = aws_route_table.publicrt.id
}

#Associating Routetable with Private Subnet
resource "aws_route_table_association" "privatertassociation"{
    depends_on = [
        aws_subnet.privatesubnet,
        aws_route_table.privatert,
    ]
    subnet_id = aws_subnet.privatesubnet.id
    route_table_id = aws_route_table.privatert.id
}

#creating public subnet
resource "aws_subnet" "publicsubnet"{
    depends_on = [aws_vpc.vpc,]
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "publicsubnet_tf"
    }
#   map_public_ip_on_launch = true
}

#creating private subnet
resource "aws_subnet" "privatesubnet"{
    depends_on = [
        aws_vpc.vpc,
        ]
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "privatesubnet_tf"
    }
#    map_public_ip_on_launch = false
}

#creating a nat instance (Bastion Host)
resource "aws_instance" "natinstance"{
    depends_on = [
        aws_security_group.sg1,
    ]

    ami = "ami-0715c1897453cabd1"
    instance_type = "t2.micro"
    key_name = "test_bijji"
    subnet_id = aws_subnet.publicsubnet.id
    vpc_security_group_ids = [aws_security_group.sg1.id]

    tags = {
        Name = "webserver_tf"
    }
    source_dest_check = false
    associate_public_ip_address = true

    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("C:\\Users\\yella\\Documents\\AWS\\test_bijji.pem")
        host        = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y squid",  # Install Squid proxy server
            "sudo systemctl enable squid",
            "sudo systemctl start squid",
        ]
    }
}

#Create a network interface
resource "aws_network_interface" "my_network_interface" {
  subnet_id   = aws_subnet.privatesubnet.id
  private_ips = ["10.0.2.10"]
  security_groups = [aws_security_group.sg2.id]
}

#creating an app instance
resource "aws_instance" "appinstance"{
    ami = "ami-0715c1897453cabd1"
    instance_type = "t2.micro"
    key_name = "test_bijji"

    network_interface {
    network_interface_id = aws_network_interface.my_network_interface.id
    device_index         = 0
    }

    tags = {
        Name = "appserver_tf"
    }
    user_data = file("user_data.sh")
}

#creating a security group for nat instance
resource "aws_security_group" "sg1"{
    vpc_id = aws_vpc.vpc.id
    description = "Security Group for Web Server"

    ingress {
            description = "Ingress CIDR"
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["76.104.46.140/32", "70.106.221.84/32"]
        }
    ingress {
            description = "Ingress CIDR"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["76.104.46.140/32", "70.106.221.84/32"]
        }
    ingress {
            description = "Ingress CIDR"
            from_port = 443
            to_port = 443
            protocol = "tcp"
            cidr_blocks = ["76.104.46.140/32", "70.106.221.84/32"]
        }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "webserversg_tf"
    }
}

#creating a security group for app instance
resource "aws_security_group" "sg2"{
    vpc_id = aws_vpc.vpc.id
    description = "Security group for App Server"

    ingress {
            description      = "Ingress proxy"
            from_port        = 3128  # Adjust to the proxy server's port
            to_port          = 3128  # Adjust to the proxy server's port
            protocol         = "tcp"
            security_groups  = [aws_security_group.sg1.id]  # Allow communication with NAT server
            }
    ingress {
            description = "Ingress CIDR"
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["10.0.1.0/24"]
        }
    ingress {
            description = "Ingress CIDR"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["10.0.1.0/24"]
        }
    ingress {
            description = "Ingress CIDR"
            from_port = 443
            to_port = 443
            protocol = "tcp"
            cidr_blocks = ["10.0.1.0/24"]
        }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "appserversg_tf"
    }
}

output "appinstance_public_ip" {
  value = aws_instance.appinstance.private_ip
}

output "nat_server_ip" {
  value = aws_instance.natinstance.public_ip
}