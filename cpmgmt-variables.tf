variable "mgmt-sku" {
    description = "Choose the plan to deploy"
    default     = "mgmt-byol"
}
variable "mgmt-version" {
    description = "Choose the version to deploy: either r8040, r81 or r8110"
    default     = "r8110"
}
variable "mgmt-size" {
    description = "Choose the vm-size to deploy"
    default     = "Standard_D2_v2"
}
variable "mgmt-admin-pwd" {
    description = "The password of the mgmt admin"
}
variable "mgmt-sku-enabled" {
    description = "Have you ever deployed a chkp management before? set to false if not"
    type        = bool
    default     = true
}
