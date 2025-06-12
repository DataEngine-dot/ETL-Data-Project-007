variable "bucket_name" {
  type    = string
  default = ""
}

variable "db_host" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  default = "team@email.com"
}
