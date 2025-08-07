# Application Deployment on GCP

## Architecture Overview

The solution leverages Google Cloud Platform's serverless and managed services to create a highly scalable and cost-effective deployment for the Insight-Agent application. The architecture is centered around a serverless API that is not publicly accessible, enhancing its security posture.

The core components and their interactions are as follows:

1.  **Application:** A lightweight Python Flask application (`app.py`) is containerized using a `Dockerfile`.
2.  **Containerization & Registry:** The `Dockerfile` packages the application into a Docker image. This image is stored in **Artifact Registry**.
3.  **CI/CD Pipeline:** A **GitHub Actions** workflow automates the build and deployment process.
    -   A `push` to the `main` branch triggers the pipeline.
    -   The pipeline builds the Docker image, tags it with a unique ID, and pushes it to Artifact Registry.
    -   The pipeline then uses the new image tag to trigger a `terraform apply` command, which updates the **Cloud Run** service.
4.  **Serverless Deployment:** The application runs on **Cloud Run**, a fully managed serverless platform. This abstracts away the underlying infrastructure, allowing the service to scale automatically to zero, minimizing costs when not in use.
5.  **Infrastructure as Code:** The entire infrastructure on GCP is provisioned and managed using **Terraform**. This ensures consistency, reproducibility, and version control of the environment.
6.  **Security:**
    -   The Cloud Run service is configured to not be publicly accessible. It can only be invoked by authenticated requests, which in a production scenario would be from a VPC network, a load balancer, or another service with the correct IAM permissions.
    -   The Cloud Run service runs with a dedicated, least-privilege **Service Account**, adhering to the principle of least privilege.
    -   All GCP resources are scoped within a dedicated project, and required APIs are enabled programmatically.



    -   **Passing Image Tag to Terraform:** The most critical part of the CI/CD pipeline is passing the dynamically generated Docker image tag to the Terraform deployment step. The pipeline accomplishes this by building the image, and then setting an environment variable that the Terraform `apply` command can consume. This ensures that the correct version of the application is deployed. A unique tag (like a commit SHA) is used to prevent collisions and ensure a new image is always deployed.

## Setup and Deployment Instructions

This guide will walk you through setting up the necessary prerequisites to deploy this project.

### Prerequisites

1.  **Google Cloud Account:** You must have a GCP account with billing enabled.
2.  **GitHub Repository:** Fork this repository to your own GitHub account.
3.  **Service Account Key:** You will need a GCP Service Account key to authenticate GitHub Actions with your GCP project. This key must have the necessary permissions to manage the resources provisioned by Terraform.
    -   Create a new Service Account in your GCP project (e.g., `github-actions-sa`).
    -   Grant this service account the following roles:
        -   `Project Owner` (for a new project) or more granular roles like:
            -   `Cloud Build Editor`
            -   `Artifact Registry Administrator`
            -   `Cloud Run Admin`
            -   `Service Account User`
            -   `IAM Service Account Key Admin`
    -   Generate a JSON key for this service account and save it.
4.  **GitHub Secrets:** You need to store the Service Account key and your GCP Project ID as GitHub Secrets.
    -   In your GitHub repository, go to `Settings > Secrets and variables > Actions`.
    -   Add two new secrets:
        -   `GCP_SA_KEY`: Paste the entire JSON content of your Service Account key here.
        -   `GCP_PROJECT_ID`: The ID of your GCP project.
5.  **Terraform CLI:** Install Terraform on your local machine if you want to test the Terraform code locally.

### Deployment Flow

1.  **Commit and Push:** Make a change to the `app.py` file or any other code in the `app/` directory.
2.  **Push to main:** Push your changes to the `main` branch of your repository.
    ```bash
    git add .
    git commit -m "feat: adding new functionality"
    git push origin main
    ```
3.  **GitHub Actions Trigger:** The push will automatically trigger the GitHub Actions workflow defined in `.github/workflows/main.yml`.
4.  **Pipeline Execution:** You can monitor the pipeline's progress in the "Actions" tab of your GitHub repository. The pipeline will perform the following steps:
    -   **Checkout Code:** Clones the repository.
    -   **Authenticate to GCP:** Uses the `GCP_SA_KEY` to authenticate with your GCP project.
    -   **Setup Terraform:** Installs the Terraform CLI.
    -   **Build & Push Docker Image:** Builds the Docker image, tags it with the commit SHA, and pushes it to Artifact Registry.
    -   **Deploy with Terraform:** Initializes Terraform, validates the configuration, and applies the changes. The Terraform plan will see the new image tag and update the Cloud Run service.

Once the pipeline completes successfully, your application will be deployed and running on Cloud Run.
