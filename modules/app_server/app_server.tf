# --------------------------------
# App Server
# --------------------------------
resource "aws_instance" "app_server" {
    ami = "ami-027fff96cc515f7bc"
    instance_type = "t2.micro"
    key_name = var.key_pair
    subnet_id = var.public1CID
    iam_instance_profile        = aws_iam_instance_profile.app_instance_profile.name
    vpc_security_group_ids = [ 
        var.app_sg_id,
        var.opmng_sg_id
     ]
    associate_public_ip_address = true
    tags = {
        Name = "${var.project}-${var.env}-app-server"
        Project = var.project
        Environment = var.env
        Type = "app"
    }
    user_data = <<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y java-17-amazon-corretto awscli

        echo "RDS_ENDPOINT=${var.rds_endpoint}" >> /etc/environment
        echo "DB_USERNAME=${var.db_username}" >> /etc/environment
        echo "DB_PASSWORD=${var.db_password}" >> /etc/environment
        source /etc/environment

        mkdir -p /app
        chown ec2-user:ec2-user /app

        aws s3 cp s3://${var.jar_s3_bucket}/${var.jar_s3_key} /app/app.jar

        # systemdサービスとして常時起動
        cat <<EOT > /etc/systemd/system/springboot.service
        [Unit]
        Description=Spring Boot Application
        After=network.target

        [Service]
        User=ec2-user
        EnvironmentFile=/etc/environment
        WorkingDirectory=/app
        ExecStart=/usr/bin/java -jar /app/app.jar --spring.profiles.active=prod
        SuccessExitStatus=143
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
        EOT

        systemctl daemon-reload
        systemctl enable springboot
        systemctl start springboot
    EOF
}

# --------------------------------
# Route53
# --------------------------------
# resource "aws_route53_zone" "route53_zone" {
#   name = "naoki-personal.com"
#   force_destroy = false

#   tags = {
#     Name = "${var.project}-${var.env}-domain"
#     Project = var.project
#     Env = var.env
#   }
# }

# resource "aws_route53_record" "api" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "api.example.com"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.app_server.public_ip]
# }

# --------------------------------
# IAM Role
# --------------------------------
resource "aws_iam_role" "app_ec2_role" {
  name = "${var.project}-${var.env}-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "${var.project}-${var.env}-app-instance-profile"
  role = aws_iam_role.app_ec2_role.name
}