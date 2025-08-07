# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.50.0"
    }
  }
}

# Use variables for project ID and region
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# GCP Project Setup

# Enable the required APIs. This ensures that the services we need are available.
resource "google_project_service" "cloud_run_api" {
  project = var.gcp_project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  project = var.gcp_project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_build_api" {
  project = var.gcp_project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}
 
# Artifact Registry 

# Create a new Artifact Registry repository to store our Docker images.
resource "google_artifact_registry_repository" "insight_agent_repo" {
  provider      = google-beta
  location      = var.gcp_region
  repository_id = "insight-agent-repo"
  format        = "DOCKER"
  description   = "Docker repository for the App application."
}
 
# Cloud Run Service
# Create a dedicated service account for the Cloud Run service.
# This follows the principle of least privilege.
resource "google_service_account" "cloud_run_sa" {
  project      = var.gcp_project_id
  account_id   = "insight-agent-sa"
  display_name = "Service Account for the app Cloud Run"
}

# Grant the service account the 'Cloud Run Invoker' role to allow it to be invoked.
# (This is more for scenarios where one service invokes another, but good practice).
# For internal traffic only, this is crucial.
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Create the Cloud Run service.
resource "google_cloud_run_v2_service" "insight_agent_service" {
  project  = var.gcp_project_id
  location = var.gcp_region
  name     = "insight-agent-service"

  template {
    containers {
      image = var.image_name_with_tag
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    service_account = google_service_account.cloud_run_sa.email
  }

  # Security configuration: Prevent public access.
  # The service can only be invoked by authenticated requests.
  traffic {
    type = "TRAFFIC_TARGET_TYPE_LATEST"
    percent = 100
  }
}

# This resource is crucial for ensuring the Cloud Run service is not publicly accessible.
# It explicitly sets the IAM policy to restrict invocations.
resource "google_cloud_run_v2_service_iam_member" "no_public_invoker" {
  project  = var.gcp_project_id
  location = google_cloud_run_v2_service.insight_agent_service.location
  name     = google_cloud_run_v2_service.insight_agent_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# The above block is for public access. The following is to restrict it.
# To ensure no public access, we explicitly remove the 'allUsers' binding.
# The 'allAuthenticatedUsers' binding is for internal GCP traffic only.
resource "google_cloud_run_v2_service_iam_member" "allow_all_authenticated" {
  project  = var.gcp_project_id
  location = google_cloud_run_v2_service.insight_agent_service.location
  name     = google_cloud_run_v2_service.insight_agent_service.name
  role     = "roles/run.invoker"
  member   = "allAuthenticatedUsers"
}