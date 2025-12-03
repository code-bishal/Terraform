provider "aws" {
    region = "us-east-1"
  
}

provider "vault" {
  address = "http://18.204.56.198:8200"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
    role_id="8485c8bf-fe9a-2cb0-9deb-173444bf0b69"
    secret_id="5b0303cc-d946-4c9e-5b72-eda625baea39"
    
    }
  }
}

data "vault_kv_secret_v2" "name" {
  mount = "kv"
  name  = "data"
}
output "name" {
  value = {
    public_ip = data.vault_kv_secret_v2.name.data["username"]
    # private_ip = aws_instance.demo_ec2.private_ip
  }
}