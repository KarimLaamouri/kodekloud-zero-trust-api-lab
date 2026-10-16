# Lab 03: IAM & Least-Privilege Role Provisioning

## 🎯 Objective
Establish a rigorous, secure Identity and Access Management (IAM) perimeter by reverse-engineering manual AWS Management Console (ClickOps) steps into a fully reproducible, idempotent Bash automation script. 

This lab enforces core Zero-Trust principles—specifically **least-privilege access**—by provisioning decoupled, purpose-specific IAM service roles for serverless compute components with strictly bounded resource permissions.

---

## 🏗️ Architecture & Component Flow
The automation script provisions and validates the following IAM resources in us-east-1:
1. Shared Trust Relationship: Dynamically generates a secure JSON trust policy allowing the AWS Lambda service principal (`lambda.amazonaws.com`) to assume execution roles via `sts:AssumeRole`.
2. Role 1 (`LambdaDynamoDBReader`):
   - **Description**: Allows Lambda to read data from DynamoDB tables.
   - **Attached Policies**: 
     - `AWSLambdaBasicExecutionRole` (for CloudWatch Logs debugging).
     - `AmazonDynamoDBReadOnlyAccess` (for read operations against NoSQL data layers).
3. Role 2 (`LambdaSNSPublisher`):
   - **Description**: Allows Lambda to publish messages to SNS topics.
   - **Attached Policies**: 
     - `AWSLambdaBasicExecutionRole` (for CloudWatch Logs debugging).
     - `AmazonSNSFullAccess` (for event notification publishing).

---

## 📂 Directory Structure

```text
lab-03-iam/
├── README.md
└── bash/
    └── lab_execution.sh
```

---

## 🚀 Usage / How to Run

1. Navigate to the script directory:
   ```bash
   cd lab-03-iam/bash
   ```

2. Execute the automation script using the Bash interpreter (recommended to bypass local permission restrictions):
   ```bash
   bash lab_execution.sh
   *(Alternatively, if you prefer running it directly, ensure permissions are granted: chmod +x lab_execution.sh && ./lab_execution.sh)*
   ```

---

## ✅ Verification Audit
Upon successful execution, the script automatically queries AWS to output structured validation tables and policy documents verifying:
- Successful creation, descriptions, and creation timestamps for both `LambdaDynamoDBReader` and `LambdaSNSPublisher` roles.
- Attached policy compliance, ensuring each role holds *only* the minimum required permissions for its specific architectural scope.
- Trust relationship validation confirming correct `lambda.amazonaws.com` service principal assumption bindings.
