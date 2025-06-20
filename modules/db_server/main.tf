# --------------------------------
# KeyPair
# --------------------------------
resource "aws_key_pair" "keypair" {
    key_name = "${var.project}-${var.env}-keypair"
    public_key = file("./src/household-dev-keypair.pub")
    tags = {
        Name = "${var.project}-${var.env}-keypair"
        Project = var.project
        Environment = var.env
    }
}

resource "aws_instance" "ondemand-db" {
  ami                    = "ami-027fff96cc515f7bc"
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-1c"
  key_name               = aws_key_pair.keypair.id
  subnet_id              = var.public1CID
  vpc_security_group_ids = [
    var.db_sg_id,
    var.opmng_sg_id
    ]
  associate_public_ip_address = true
  ebs_optimized          = false
  iam_instance_profile = aws_iam_instance_profile.ec2_ebs_profile.name

  tags = {
    Name    = "${var.project}-${var.env}-ondemand-db"
    Project = var.project
    Env     = var.env
    Type    = "ondemand"
  }

  user_data = <<-EOF
            #!/bin/bash
            # エラーが発生したら即座に終了
            set -e

            # /dev/xvdf が見えるまで最大60秒待機
            for i in {1..60}; do
                if [ -b /dev/xvdf ]; then
                    echo "/dev/xvdf is available"
                    break
                fi
                echo "Waiting for /dev/xvdf to be attached..."
                sleep 1
                if [ $i -eq 60 ]; then
                    echo "/dev/xvdf did not appear in time"
                    exit 1
                fi
            done

            # /dev/xvdf がフォーマットされていなければ初期化
            if ! blkid /dev/xvdf; then
                mkfs -t xfs /dev/xvdf
            fi

            # マウントポイントの作成
            mkdir -p /data
            
            # ボリュームのマウント
            mount /dev/xvdf /data
            
            # 永続的なマウントの設定
            echo "/dev/xvdf /data xfs defaults,nofail 0 2" >> /etc/fstab

            # パッケージの更新
            sudo dnf update -y

            # 既存パッケージの削除
            sudo dnf remove -y mariadb-*

            # MySQLのリポジトリをyumに追加
            sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 

            # MySQLのインストール
            wget https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
            sudo rpm --import RPM-GPG-KEY-mysql-2023
            sudo dnf --enablerepo=mysql80-community install -y mysql-community-server mysql-community-devel

            # MySQLサービスを停止
            sudo systemctl stop mysqld

            # 既存のデータディレクトリをバックアップ
            if [ -d /var/lib/mysql ]; then
                sudo mv /var/lib/mysql /var/lib/mysql.bak
            fi

            # データディレクトリの作成と権限設定
            sudo mkdir -p /data/mysql
            sudo chown -R mysql:mysql /data/mysql
            sudo chmod 750 /data/mysql

            # シンボリックリンクの作成
            sudo ln -sf /data/mysql /var/lib/mysql

            # 初回セットアップ時のMySQL初期化
            if [ ! -d /data/mysql/mysql ]; then
                echo "First time setup: Initializing MySQL..."
                # 既存のデータディレクトリを完全にクリーンアップ
                sudo rm -rf /data/mysql/*
                sudo rm -rf /var/lib/mysql/*
                # MySQLの初期化を実行
                sudo mysqld --initialize --user=mysql
                echo "MySQL initialization completed"
            else
                echo "Using existing MySQL data directory"
            fi

            # ログファイルの作成と権限設定
            sudo touch /var/log/mysqld.log
            sudo chown mysql:mysql /var/log/mysqld.log
            sudo chmod 640 /var/log/mysqld.log

            # SELinuxが有効な場合のみ設定を実行
            if [ "$(getenforce)" != "Disabled" ]; then
                sudo dnf install -y policycoreutils-python
                sudo semanage fcontext -a -t mysqld_db_t "/data/mysql(/.*)?"
                sudo restorecon -R /data/mysql
            fi

            # MySQLの起動前にデータディレクトリの権限を再確認
            sudo chown -R mysql:mysql /data/mysql
            sudo chmod -R 750 /data/mysql

            # my.cnfのdatadirとsocketを修正
            sudo sed -i 's|^datadir=.*|datadir=/data/mysql|' /etc/my.cnf
            # sudo sed -i 's|^socket=.*|socket=/data/mysql/mysql.sock|' /etc/my.cnf

            # MySQLの起動
            sudo systemctl start mysqld

            # サービスの有効化
            sudo systemctl enable mysqld

            # 起動確認とログ出力
            for i in {1..30}; do
                if sudo systemctl is-active --quiet mysqld; then
                    echo "MySQL started successfully"
                    # 起動直後のログを確認
                    sudo tail -n 20 /var/log/mysqld.log
                    break
                fi
                if [ $i -eq 30 ]; then
                    echo "MySQL failed to start"
                    # エラー時のログを確認
                    sudo tail -n 50 /var/log/mysqld.log
                    exit 1
                fi
                sleep 1
            done

            sudo reboot
            EOF
}

# ---------------------------------------------
# ebs volume
# ---------------------------------------------
resource "aws_ebs_volume" "db-volume" {
    availability_zone = "ap-northeast-1c"
    size = 20
    type = "gp3"
    tags = {
        Name = "${var.project}-${var.env}-db-volume"
        Project = var.project
        Env = var.env
    }
}

resource "aws_volume_attachment" "db-volume-attachment" {
    depends_on = [ aws_instance.ondemand-db ]
    device_name = "/dev/xvdf"
    instance_id = aws_instance.ondemand-db.id
    volume_id = aws_ebs_volume.db-volume.id
}

resource "aws_iam_role" "ec2_ebs_role" {
  name = "${var.project}-${var.env}-ec2-ebs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAMポリシーの作成
resource "aws_iam_role_policy" "ec2_ebs_policy" {
  name = "${var.project}-${var.env}-ec2-ebs-policy"
  role = aws_iam_role.ec2_ebs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DetachVolume",
          "ec2:AttachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAMインスタンスプロファイルの作成
resource "aws_iam_instance_profile" "ec2_ebs_profile" {
  name = "${var.project}-${var.env}-ec2-ebs-profile"
  role = aws_iam_role.ec2_ebs_role.name
}