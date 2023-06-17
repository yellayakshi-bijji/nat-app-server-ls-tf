#storing the terraform state file in s3 bucket
terraform {
  backend "s3" {
    bucket = "chocolatekibalti"
    key    = "terraform-module/natappserver-lamp/natappserverls.tfstate"
    region = "us-east-1"
  }
}