# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.50.0.0/16" # uma classe de IP
  instance_tenancy = "default"  # - (Optional) A tenancy option for instances launched into the VPC. Default is default, which makes your instances shared on the host. Using either of the other options (dedicated or host) costs at least $2/hr.

  tags = {
    Name = "vpc-turma3-simone-2"
  }
}

output name {
  value = aws_vpc.main.id
}


resource "aws_subnet" "my_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.50.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-turma3-simone-tf"
  }
}

output name_subnet {
  value = aws_subnet.my_subnet_a.id
}

resource "aws_subnet" "my_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.50.20.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-turma3-simone-tf-b"
  }
}

output name_subnet_b {
  value = aws_subnet.my_subnet_b.id
}

resource "aws_subnet" "my_subnet_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.50.30.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-turma3-simone-tf-c"
  }
}

output name_subnet_c {
  value = aws_subnet.my_subnet_c.id
}


// internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws_internet_gateway_simone-tf"
  }
}


//route table
resource "aws_route_table" "rt_terraform" {
  vpc_id = aws_vpc.main.id

  route = [
      {
        carrier_gateway_id         = ""
        cidr_block                 = "0.0.0.0/0"
        destination_prefix_list_id = ""
        egress_only_gateway_id     = ""
        gateway_id                 = aws_internet_gateway.gw.id
        instance_id                = ""
        ipv6_cidr_block            = ""
        local_gateway_id           = ""
        nat_gateway_id             = ""
        network_interface_id       = ""
        transit_gateway_id         = ""
        vpc_endpoint_id            = ""
        vpc_peering_connection_id  = ""
      }
  ]

  tags = {
    Name = "route_table_simone_tf"
  }
}

//associate
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet_a.id
  route_table_id = aws_route_table.rt_terraform.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.my_subnet_b.id
  route_table_id = aws_route_table.rt_terraform.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.my_subnet_c.id
  route_table_id = aws_route_table.rt_terraform.id
}

//security group
resource "aws_security_group" "allow_ssh" {
  name        = "security-group-turma3-simone-tf"
  description = "Allow SSH inbound traffic"
  #   vpc_id = "vpc-038ec104e41ea3337"
  vpc_id = aws_vpc.main.id


  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      #cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null,
      description      = "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "allow_ssh"
  }
}


resource "aws_key_pair" "public_key" {
  key_name   = "public_key_simone_bastion_virginia_tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/QihOxsloez2BX6g5DWCV/D99l7voG6IBBl5a8keuFghPcbbmtXrlkLLBSNFIaGTuazINGi/MZkEahtZLuritPIzX4zXfEZidp5U4nV/tlXetaiEFUCUwVy7ha509f8pqoJCDybA1XBKE06D5OiKeNL3itoYDaeKtAK4kSMvd4aIPUpQugdxZ+nqQ8+7RYSql7UoDOcoMV5v0/2SKK8WMyrpG/vF4efOrm4SULQGQ5WsNb2/ku6Zxc8hprU6eQQqMlVMw2bHuPaOXKfoT/8d7ASYU40PP3EaZhRAKL3T/ZlHzJCDQBZGafUloAElS5MvoOdgo3KG4Pzodvdv3FTw5Ytf5pZIkC6OaR0lCaZEb8DOKKR4FjbvOCDKQ1lVU6fl7nlKFk4DcbAnneyw6hbONTaX5wj0q8rAEZuHeL0stEgxtVK+OccrkWp/WYWueKWXw4B2u9H1ejkwOEsrFhseWMKJlMF93H/hIsFMT38o4SnwXtIzQnajaagpKBaMYC6M= ubuntu@turma3-simone-ec2"
}

resource "aws_instance" "ec2" {
  subnet_id                   = aws_subnet.my_subnet_a.id
  ami                         = "ami-0279c3b3186e54acd"
  count                       = 1
  instance_type               = "t2.large"
  key_name                    = "public_key_simone_bastion_virginia_tf"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}"]
  root_block_device {
    encrypted   = true
    volume_size = 8
  }
  tags = {
    Name = "ec2-turma3-simone-tf-${count.index}"
  }
  depends_on = [
    aws_key_pair.public_key, #também funcionaria só o aws_key_pair.public_key
    aws_security_group.allow_ssh
  ]
}


# resource "aws_network_interface" "my_subnet" {
#   subnet_id           = aws_subnet.my_subnet.id
#   private_ips         = ["172.17.10.100"] # IP definido para instancia
#   # security_groups = ["${aws_security_group.allow_ssh1.id}"]

#   tags = {
#     Name = "primary_network_interface my_subnet"
#   }
# }

output "ssh" {
  value = [
    for web in aws_instance.ec2 :
    <<EOF
          Name: ${web.tags_all.Name}
          ssh -i id_rsa ubuntu@${web.public_ip}
          Public ip: ${web.public_ip}
        EOF
  ]
}