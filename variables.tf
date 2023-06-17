variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "allowallcidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "avail_zone" {
  type    = string
  default = "us-east-1a"
}

variable "linux_ami_id" {
  type    = string
  default = "ami-04a0ae173da5807d3"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "keypair" {
  type    = string
  default = "test_bijji"
}

variable "myip" {
  type    = string
  default = "76.104.46.140/32"
}

variable "officeip" {
  type    = string
  default = "70.106.221.84/32"
}