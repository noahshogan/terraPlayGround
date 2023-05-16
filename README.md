# Terraform AWS Lambda Project

This repository contains Terraform configuration to set up an AWS environment with S3, DynamoDB, and Lambda function. The Lambda function triggers when a new object is created in the S3 bucket, retrieves the object, and stores it in DynamoDB.

## Project Structure

The project has the following structure:


app ---------------------------- Directory for the Lambda function code and its dependencies

app/tests --------------------- Directory for the test files

app/tests/index.test.js ---- Test file for the Lambda function

app/index.js ----------------- Lambda function code

package.json --------------- File to handle dependencies for the Lambda function

main.tf ------------------------ Terraform configuration file to create AWS resources

noah.json -------------------- Sample JSON file for the S3 bucket


## Setting Up

Make sure you have the following prerequisites installed on your machine:

- [Node.js and npm](https://nodejs.org/)
- [Terraform](https://www.terraform.io/)

Clone the repository and navigate to the `app` directory:

```bash
git clone <repository-url>
cd app
```

Install the dependencies:

```bash
npm install
```

Navigate back to the root directory and initialize Terraform:

```bash
cd ..
terraform init
```

Now you can apply the Terraform configuration:

```terraform
terraform apply
```

## Running Tests

To ensure the Lambda function behaves as expected, we've included a test suite written using Jest. Here's how you can run it:

First, navigate to the `app` directory:

```bash
cd app
```

Then, run the tests:

```bash
npm test
```

This will start Jest and run any test files it discovers in the project.

## Deploying Changes

After you've made changes and tested them locally, you can use Terraform to deploy the changes to AWS. To do this, run:

```bash
terraform apply
```

Terraform will prompt you to confirm that you want to create or modify the resources described in your main.tf.

Continuous Integration (CI)
This project is set up to use GitHub Actions for Continuous Integration. Whenever changes are pushed to the repository, a GitHub Actions workflow is triggered that:

1. Checks out the code.
2. Sets up Node.js.
3. Installs the project's dependencies.
4. Runs the test suite.
   This helps to ensure that changes don't break the Lambda function or the infrastructure it depends on.

## Cleaning Up

To delete the resources created by Terraform, you can use the terraform destroy command. This will prompt you to confirm that you want to destroy the resources, preventing accidental deletions:

```bash
terraform destroy
```
