output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "public_dns" {
  value = aws_instance.this.public_dns
}

output "ssh_command" {
  value = "ssh -i <private-key-path> ubuntu@${aws_instance.this.public_ip}"
}
