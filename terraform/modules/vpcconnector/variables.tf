// vpcconnector module

variable "project_name" {
  description = "The id of the project we want to create the connector in, e.g. studybeast-prod"
  type        = string
}

variable "region" {
  description = "The region where the connector should be deployed (e.g. us-central1)"
  type        = string
}

variable "vpc_link" {
  description = "A link to the VPC in which the connector will be deployed"
}
