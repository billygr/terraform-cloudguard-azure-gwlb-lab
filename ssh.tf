# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.example_ssh.private_key_pem
  filename        = "azureuser.pem"
  file_permission = "0600"
}
