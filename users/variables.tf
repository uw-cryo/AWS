variable "user" {
  description = "Tacolab account users"
  type        = set(string)
  default     = ["eric", "quinn", "seth"]
}

variable "poweruser" {
  description = "Tacolab account powerusers"
  type        = list(string)
  default     = ["dshean", "scottyh", "quinn"]
}
