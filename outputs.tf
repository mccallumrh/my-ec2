output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.test_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.test_server.public_ip
}

output "private_key_filename" {
  description = "The local path where the private key was saved"
  value       = local_file.private_key_pem.filename
}
