# Multi-Repository CI/CD Setup

This directory contains GitHub Actions workflows for a multi-repository CI/CD setup.

## Repository Architecture

The CI/CD pipeline spans across two types of repositories:

1. **Service Repositories**: Each microservice has its own repository with application code and Dockerfile
2. **Infrastructure Repository**: This repository contains all infrastructure code (Terraform, Helm)

## Workflow Overview

The CI/CD process is split across these repositories:

1. **CI Pipeline** (in service repositories) - Builds and publishes Docker images
2. **Update and Deploy Workflow** (in this infrastructure repository) - Updates Helm values and deploys services

## Workflow in Service Repositories

Each service repository should have a CI workflow that:

- Triggers on code changes
- Builds the Docker image
- Runs tests
- Pushes the image to Amazon ECR
- Triggers the deployment workflow in this infrastructure repository

An example CI workflow for service repositories is provided in `.github/ci-example-for-service-repo.yml`.

## Workflow in Infrastructure Repository

This repository contains the `update-and-deploy.yml` workflow that:

- Is triggered by service repository CI workflows
- Updates the appropriate Helm values file with the new image tag
- Deploys or upgrades the service using Helm

## Setup Instructions

### 1. In Each Service Repository:

1. Create a `.github/workflows` directory
2. Copy the example CI workflow from this repo's `.github/ci-example-for-service-repo.yml`
3. Update the following variables:
   - `SERVICE_NAME`: The name of your service
   - `INFRA_REPO`: The GitHub repo path to this infrastructure repository
4. Add a GitHub secret:
   - `INFRA_REPO_TOKEN`: A GitHub personal access token with workflow permissions on the infrastructure repo

### 2. In This Infrastructure Repository:

1. Ensure Helm values files exist for each service:
   - `helm/values/dev/<service-name>.yaml`
   - `helm/values/prod/<service-name>.yaml`
2. Add GitHub secrets:
   - `AWS_ACCESS_KEY_ID`: AWS access key with permissions for EKS
   - `AWS_SECRET_ACCESS_KEY`: Corresponding AWS secret key

## How It Works

1. Developer pushes code to a service repository
2. Service repository CI workflow:
   - Builds and tests the code
   - Creates a Docker image with a unique tag
   - Pushes the image to ECR
   - Triggers the update-and-deploy workflow in this repo
3. This repo's update-and-deploy workflow:
   - Updates the Helm values file with the new image tag
   - Deploys the updated service to the appropriate environment

## Troubleshooting

### Service Not Deploying
- Check if the service values file exists in the correct environment directory
- Verify that the GitHub token has sufficient permissions
- Check GitHub Actions logs in both repositories

### Image Not Found
- Ensure the ECR repository exists
- Check that the service has proper ECR permissions
- Verify the image tag format in the Helm values file 