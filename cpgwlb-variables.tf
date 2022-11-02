variable "gwlb-vmss-agreement" {
    description = "Have you ever deployed a ckp management before? set to false if not"
    type        = bool
    default     = true
}
variable gwlb-name {
    description = "Choose the name gwlb gateway name"
    type        = string
    default     = "cpgwlbvmss"
}
variable gwlb-size {
    description = "Choose the gwlb size"
    type        = string
    default     = "Standard_DS1_v2"
}
variable gwlb-vmss-min {
    description = "The min number of gateways"
    type        = string
    default     = "2"
}
variable gwlb-vmss-max {
    description = "The max number of gateways"
    type        = string
    default     = "3"
}
variable "cpgw-admin-pwd" {
    description = "The password of the VMSS gw admin"
}
variable "chkp-sic" {
    description = " Azure GW sic"
    default="123456789012"
}
