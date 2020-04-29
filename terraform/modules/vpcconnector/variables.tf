// vpcconnector module

variable "region" {
  description = "The region where the connector should be deployed (e.g. us-central1)"
  type        = string
}

variable "vpc_link" {
  description = "A link to the VPC in which the connector will be deployed"
}
