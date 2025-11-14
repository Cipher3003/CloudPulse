terraform{
    backend "s3" {
      bucket = "terraform-tfstate-202526"
      key = "terraform.tfstate"
      region = "eu-north-1"
    }
}