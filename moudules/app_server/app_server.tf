# --------------------------------
# KeyPair
# --------------------------------
resource "aws_key_pair" "app_server_key" {
    key_name = "${var.project}-${var.env}-keypair"
    public_key = file("./src/household-dev-keypair.pub")
    tags = {
        Name = "${var.project}-${var.env}-keypair"
        Project = var.project
        Environment = var.env
    }
}

# --------------------------------
# App Server
# --------------------------------
resource "aws_instance" "app_server" {
    ami = data.aws_ami.app.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.app_server_key.key_name
    subnet_id = var.public1CID
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
}

