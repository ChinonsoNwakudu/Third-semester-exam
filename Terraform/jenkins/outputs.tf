output "ec2_public_ip" {
  value = aws_instance.exam-server.public_ip
}