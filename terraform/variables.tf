variable "gcp_project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}

# This variable will be set by the CI/CD pipeline
variable "image_name_with_tag" {
  description = "The full image name and tag of the container to deploy."
  type        = string
}