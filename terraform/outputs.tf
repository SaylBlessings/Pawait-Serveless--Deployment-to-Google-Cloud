output "cloud_run_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.insight_agent_service.uri
}

output "artifact_registry_repo_url" {
  description = "The URL of the Artifact Registry repository."
  value       = google_artifact_registry_repository.insight_agent_repo.name
}