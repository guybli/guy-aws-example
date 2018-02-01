variable access_key {
  description = "please enter your AWS access key"
}

variable secret_key {
  description = "please enter your AWS secret key"
}

variable "region" {
  description = "please enter the AWS region."
}

variable "key_name" {
  description = "please enter  the AWS key pair to use for resources."
}

variable "key_path" {
  description = "please enter your ssh key path
}

variable "ami" {
  type        = "map"
  description = "A map of AMIs"

  default = {
    #eu-west-2 = "ami-524e5736"
    #eu-west-2 = "ami-fdc9d299"
    eu-west-2 = "ami-07081263"
  }
}

variable "instance_type" {
  description = "The instance type to launch."
  default     = "t2.micro"
}

variable "instance_ips" {
  description = "The IPs to use for our instances"
  default     = ["10.0.1.20", "10.0.1.21"]
}
