########
 # Vars #

variable "aws_region" { default = "eu-west-3" } # Paris

 # AWS SDK auth
provider "aws" {
    region = "${var.aws_region}"
  	access_key = "AKIA54MRT3Y2ZGFDOBVH"
	secret_key = "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"
}

 # SSH keys #

resource "aws_key_pair" "admin" {
  key_name   = "admin-key"

  # contenu du fichier : ssh-keys/admin-user.pub
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA5EYd8I5pqPIGBm352UFBOtlDdZDonqmyaxIKdokQup0joLTeYYOap6FlrYsX2Viak+2vmPk1tFDefGm9AHnw3XdLynKj/L+m2vMUMNlAWDX3Yb+5jKi3qdoj4puNJB2nr04aYWMFozbCt1cUVunu84ck+CDrUc1yUIcNUkuMUP6Y/D0+FXph3H+RKTsSFJ+JTeXcEFFodgFhiSpL+/BPcQWtxSxNwVBrxAGD40kBVXeJpmSn7gUvYDz4Wn983gcm5nRJ400BbCVF4okg1K/LBNBPbVSh92ZZiEEpjzzhVNcvpzKZyZHAj37ec+POiCTbaCFm4+pL2AFzG7Jbhuv3 hass@centos"
}


resource "aws_key_pair" "ansible" {
  key_name   = "ansible-key"

  # contenu du fichier : ssh-keys/ansible-user.pub
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQNrEZQQuIzWe+LMsvJQgydKu+IgntUhnPob614VwSwfwRTJwH7bayDZDfKwQWEqpPkDPDFod8YUUUUT+mCJxgPsM6yf6hMunQGv6s1nE/e/zORYppz1cwELKd+pDQV+PN2xr/bRzYl1wmF+BJ3JNorW4V+2aNue7zuvgfmYI4zVXHg4M5vCyz9QCtBvNZtLFt5uFDngwu9zlSwXzRmUzqgJRNevrXBC/lunwYfEf5pwMvmsL/y0ppS2GxEuEJIF4q+tXn6B4qN1DmsnTK+zgz6svtiv6vmPwRiIAJf5c+JgPKjVEOG87hecrvLFIZidKpURqKYLEGrb+rnkJU+lx9 hass@centos"
}

# Get default VPC
resource "aws_default_vpc" "default" {
    tags {
        Name = "Default VPC"
    }
}

resource "aws_subnet" "web-public-2a" {
    cidr_block = "172.31.60.0/27"
    availability_zone = "${var.aws_region}a"
    vpc_id     = "${aws_default_vpc.default.id}"

    tags {
        Name = "Web"
    }
}

resource "aws_subnet" "bd-private-2a" {
    cidr_block = "172.31.50.0/27"
    availability_zone = "${var.aws_region}a"
    vpc_id     = "${aws_default_vpc.default.id}"
    tags {
        Name = "BD"
    }
}

resource "aws_security_group" "allow_remote_admin" {
  name        = "allow_remote_admin"
  description = "Allow ssh and RDP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_remote_admin"
  }
}

resource "aws_security_group" "allow_external_communication" {
  name        = "allow_external_communication"
  description = "Allow system reach other servers"

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_external_comm"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic to server"

  ingress {
    from_port   = 80 
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_web"
  }
}

resource "aws_security_group" "allow_mysql_internal" {
  name        = "allow_mysql_internal"
  description = "Allow Mysql connexion from web server"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.web-public-2a.cidr_block}"]
  }

  tags {
    Name = "allow_mysql_internal"
  }
}

resource "aws_instance" "web-terra" {
    ami           = "ami-0ad7477959189ba07"
    instance_type = "t2.micro"
    key_name = "${aws_key_pair.ansible.key_name}"  # assign ssh ansible key
    subnet_id = "${aws_subnet.web-public-2a.id}"   

    associate_public_ip_address = true

    tags {
        Name = "web-terra"
        scope = "training"
        role = "web"
    }

    security_groups = [
        "${aws_security_group.allow_web.id}",
        "${aws_security_group.allow_external_communication.id}",
        "${aws_security_group.allow_remote_admin.id}"
    ]

    root_block_device = {
        delete_on_termination = true
        volume_size = 10 
    }

}


