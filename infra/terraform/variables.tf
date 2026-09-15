variable "project_id" {
  description = "GCP project ID (shared Colette project)"
  type        = string
  default     = "valued-lyceum-508616-g0"
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the app VM"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "VM size for the single API+UI host. e2-medium (2 vCPU / 4GB) covers docs/deployment.md's 2GB API requirement plus the Next.js dev-mode UI; bump before it becomes a bottleneck, not before."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size. Holds the OS, Docker images, and the executive_data volume (ChromaDB + SQLite + company docs) — generous headroom for a 3-user internal tool."
  type        = number
  default     = 30
}
