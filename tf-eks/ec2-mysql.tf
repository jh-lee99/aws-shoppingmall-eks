# data "aws_ami" "al2023_ami" {
#   most_recent      = true
#   owners           = ["amazon"]
 
#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.*-x86_64"]
#   }
 
#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
 
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

data "aws_ami" "al2_ami" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

data "aws_key_pair" "existing_keypair" {
  key_name = "ljh-DB-key"  # 기존에 생성된 키페어의 이름을 지정합니다.
}

# # Route 53 프라이빗 호스팅 영역 생성
# resource "aws_route53_zone" "private" {
#   name = "db.com"
#   vpc {
#     vpc_id = module.vpc.vpc_id
#   }
# }

# # 마스터 인스턴스용 Route 53 레코드 생성
# resource "aws_route53_record" "master" {
#   zone_id = aws_route53_zone.private.zone_id
#   name    = "master.db.com"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.mysql_master.private_ip]
# }

# # 슬레이브 인스턴스용 Route 53 레코드 생성
# resource "aws_route53_record" "slave" {
#   zone_id = aws_route53_zone.private.zone_id
#   name    = "slave.db.com"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.mysql_slave.private_ip]
# }

resource "aws_subnet" "additional_private_subnets" {
  count                  = length(local.azs)  # 기존 AZ 수만큼 private 서브넷을 생성합니다.
  vpc_id                 = module.vpc.vpc_id
  cidr_block             = cidrsubnet(local.vpc_cidr, 8, 40 + (length(local.azs) + count.index) * 4)  # 기존 서브넷과 겹치지 않는 새로운 CIDR 블록을 생성합니다.
  availability_zone      = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    "Name" = "${local.name}-infra-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "additional_private_subnet_route_association" {
  count            = length(aws_subnet.additional_private_subnets)  # 새로 생성한 private 서브넷의 수만큼 route association을 생성합니다.
  subnet_id        = aws_subnet.additional_private_subnets[count.index].id  # 각 서브넷에 대한 ID를 지정합니다.
  route_table_id   = module.vpc.private_route_table_ids[count.index]  # 기존 private route table ID를 지정합니다.
}

##
resource "aws_security_group" "eks_node_to_db_sg" {
  name        = "eks-node-to-db-sg"
  description = "Security group for allowing EKS nodes to access DB"

  vpc_id = module.vpc.vpc_id

  // SSH 접근 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  // VPC IP에서의 SSH 접근을 허용합니다.
  }

  // MySQL 접근 허용
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  // VPC IP에서의 SSH 접근을 허용합니다.
  }

  // 인바운드 규칙: DB 포트를 열어서 접속을 허용합니다. 여기서는 MySQL 포트인 3306을 가정합니다.
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [module.eks.node_security_group_id]  // EKS 노드의 보안 그룹을 소스로 지정합니다.
  }

  # // Ping을 허용 (ICMP 에코 요청)
  # ingress {
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmp"
  #   cidr_blocks = ["10.0.0.0/8"]  // Ping을 허용할 IP 대역을 지정합니다.
  # }

  // vpc 대역을 허용 (모든 요청)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.10.0.0/16"]  // Ping을 허용할 IP 대역을 지정합니다.
  }

  // 아웃바운드 규칙: 모든 트래픽을 허용합니다.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  // 허용할 IP 대역을 지정합니다. 필요에 따라 변경하세요.
  }
}

# resource "aws_instance" "new_private_instance" {
#   count           = length(aws_subnet.additional_private_subnets)  # 새로 생성한 private 서브넷의 수만큼 인스턴스를 생성합니다.

#   ami             = data.aws_ami.al2023_ami.id  # 사용할 AMI ID를 지정하세요.
#   instance_type   = "t2.micro"   # 인스턴스 유형을 지정하세요.
#   subnet_id       = aws_subnet.additional_private_subnets[count.index].id  # 각 서브넷에 대한 ID를 지정합니다.
#   key_name        = data.aws_key_pair.existing_keypair.key_name  # 사용할 키페어의 이름을 지정하세요.
#   security_groups = [aws_security_group.eks_node_to_db_sg.id]
#   user_data       = file("userdata/userdata${count.index + 1}.sh")

#   private_ip      = cidrhost(aws_subnet.additional_private_subnets[count.index].cidr_block, 11)

#   tags = {
#     Name = "${local.name}-DB-private-instance-${count.index + 1}"
#   }

#   provisioner "file" {
#     source      = "userdata/init${count.index + 1}.sql"
#     destination = "/home/ec2-user/init.sql"

#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = file("userdata/ljh-DB-key.pem")
#       host        = self.private_ip
#     }
#   }

#   provisioner "file" {
#     source      = "userdata/my${count.index + 1}.cnf"
#     destination = "/home/ec2-user/my.cnf"

#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = file("userdata/ljh-DB-key.pem")
#       host        = self.private_ip
#     }
#   }
# }


resource "aws_instance" "mysql_master" {
  ami             = data.aws_ami.al2_ami.id  # 사용할 AMI ID를 지정하세요.
  instance_type   = "t2.micro"
  # instance_type   = "m6a.xlarge"
  subnet_id       = aws_subnet.additional_private_subnets[0].id
  security_groups = [aws_security_group.eks_node_to_db_sg.id]
  key_name        = data.aws_key_pair.existing_keypair.key_name  # 사용할 키페어의 이름을 지정하세요.
  private_ip      = cidrhost(aws_subnet.additional_private_subnets[0].cidr_block, 10)

  user_data = file("userdata/userdata1.sh")

  provisioner "file" {
    source      = "userdata/init1.sql"
    destination = "/home/ec2-user/init.sql"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }

  provisioner "file" {
    source      = "userdata/ljh-DB-key.pem"
    destination = "/home/ec2-user/ljh-DB-key.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }

  provisioner "file" {
    source      = "userdata/my1.cnf"
    destination = "/home/ec2-user/my.cnf"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }
  tags = { Name = "${local.name}-mysql-master" }
}

resource "aws_instance" "mysql_slave" {
  ami             = data.aws_ami.al2_ami.id  # 사용할 AMI ID를 지정하세요.
  instance_type   = "t2.micro"
  # instance_type   = "m6a.xlarge"
  subnet_id       = aws_subnet.additional_private_subnets[1].id
  security_groups = [aws_security_group.eks_node_to_db_sg.id]
  key_name        = data.aws_key_pair.existing_keypair.key_name  # 사용할 키페어의 이름을 지정하세요.
  private_ip      = cidrhost(aws_subnet.additional_private_subnets[1].cidr_block, 10)

  user_data = templatefile("userdata/userdata2.sh.tmpl", {
    master_ip = aws_instance.mysql_master.private_ip
  })

  provisioner "file" {
    source      = "userdata/init2.sql"
    destination = "/home/ec2-user/init.sql"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }

  provisioner "file" {
    source      = "userdata/ljh-DB-key.pem"
    destination = "/home/ec2-user/ljh-DB-key.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }

  provisioner "file" {
    source      = "userdata/my2.cnf"
    destination = "/home/ec2-user/my.cnf"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = self.private_ip
    }
  }
  tags = { Name = "${local.name}-mysql-slave" }
}

# resource "terraform_data" "sync_master_status" {
resource "null_resource" "sync_master_status" {
  depends_on = [aws_instance.mysql_master]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("userdata/ljh-DB-key.pem")
      host        = aws_instance.mysql_master.private_ip
    }

    inline = [
      "chmod 600 /home/ec2-user/ljh-DB-key.pem",
      "while ! ping -c 1 -W 1 ${aws_instance.mysql_slave.private_ip} &> /dev/null; do sleep 1; echo $(date +%F_%H:%M:%S); done",
      "while [ ! -f /tmp/master_status.txt ]; do sleep 1; echo $(date +%F_%H:%M:%S); done",
      "scp -i /home/ec2-user/ljh-DB-key.pem -o StrictHostKeyChecking=no /tmp/master_status.txt ec2-user@${aws_instance.mysql_slave.private_ip}:/tmp/master_status.txt"
    ]
  }
}

output "mysql_master_ip" {
  value = aws_instance.mysql_master.private_ip
}

output "mysql_slave_ip" {
  value = aws_instance.mysql_slave.private_ip
}