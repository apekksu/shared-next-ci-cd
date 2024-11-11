### `Shared NextJS CI/CD pipeline`
This repository provides a shared CI/CD pipeline for deploying NextJS applications to an EC2 instance.

### `Getting Started`

To use the shared CI/CD pipeline, follow these steps:

Create or clone your NestJS application repository.
Set up the correct directory structure:
    **.github/workflows/deploy.yml** with referance to this shared pipeline as shown in the example
    source files located in **/src** (**main.ts**, app-module etc.)
Commit and push to the branch mentioned in your yaml for automatic deployment.

```yaml
name: Deploy Next.js App

on:
  push:
    branches:
      - main

jobs:
  deploy:
    uses: apekksu/shared-next-ci-cd/.github/workflows/ci.yml@main
    with:
      s3-bucket-name: apekksu-next-euc1
      application-name: ${{ github.event.repository.name }}
      application-port: 3333 # allowed range 3333 - 3350
      aws-region: eu-central-1

    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### `Using organizaion level secrets`
**AWS_ACCESS_KEY_ID**: The AWS access key ID.
**AWS_SECRET_ACCESS_KEY**: The AWS secret access key.

Secrets above are required for the pipeline to authenticate with AWS and are set on organization level secrets. Ask Tigran/Aram to check if there are issues with credentials.


### `Shared pipeline performs the following tasks:`

The pipeline checks out your repository, installs dependencies, and builds the application.
The built application is zipped and uploaded to an S3 bucket.
The pipeline retrieves the shared EC2 instance information and deploys the application using AWS SSM.


### `Example Repo`
[Authentication Module](https://github.com/apekksu/cyber-folk-web-app).

Application name uses port number to easily differenciate between pm2 apps.
Use different application ports for multiple applications deployed on the same EC2 instance to avoid port conflicts.
