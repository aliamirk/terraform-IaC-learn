#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<html><h1>Hello from Terraform EC2 on Amazon Linux 2023!</h1></html>" > /var/www/html/index.html
