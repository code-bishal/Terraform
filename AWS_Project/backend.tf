terraform {
  backend "s3" {
    bucket       = "my-tf-test-bucket-hifi-wifi-workspaces"
    key          = "path/terraform.tfstate"
    region       = "us-east-1" # Change to your desired region
    encrypt      = true
    use_lockfile = true
  }
}
