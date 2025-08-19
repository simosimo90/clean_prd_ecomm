# Here I declare all the variables of my code

variable "sns_topic_arn" {
  description = "The arn of the sns topic subscription, created variable as the service is not created"
  type = string
  default = ""
}



# Variable for zip package with the order services name change, used for version control
variable "js_files_var" {
  description = "the S3 key for the order service package deployment"
  type = string
  default = "service-backend/orders.zip"
  
}


# Variable for the zip python file name change, used for  version control
variable "py_files_var" {
  description = "the S£ key for the py file deployment on the downstream service lambda"
  type = string
  default = "downstream-services/publish-data.zip"
  
}


