variable "project_id" { type = string }
variable "region"     { type = string  default = "us-central1" }
variable "cluster_name" { type = string default = "gemx-autopilot" }

variable "network"    { type = string  default = "default" }
variable "subnetwork" { type = string  default = "default" }

variable "domain"     { type = string  description = "Hostname (ex: gemx.example.com)" }
variable "acme_email" { type = string  description = "Email para ACME/Let's Encrypt"  default = "admin@example.com" }

variable "oauth_enabled"      { type = bool   default = true }
variable "google_client_id"   { type = string default = "" }
variable "google_client_secret" { type = string default = "" }
variable "allowed_domain"     { type = string default = "" }

variable "enable_traefik" { type = bool default = true }

variable "create_zone"    { type = bool default = false }
