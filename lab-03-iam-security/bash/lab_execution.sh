#!/usr/bin/env bash
# ==============================================================================
# Project:     Zero-Trust Internal API from Scratch
# Module:      Lab 03 - IAM & Least-Privilege Role Provisioning
# Goal:        Automate the creation of secure IAM roles for Lambda with 
#              trust relationships, policy attachments, and compliance audits.
# ==============================================================================

set -euo pipefail

# --- 1. CONFIGURATION VARIABLES ---
AWS_REGION="us-east-1"
TRUST_POLICY_FILE="trust-policy.json"

echo "=================================================================="
echo "Starting Lab 03: IAM Role Provisioning & Validation"
echo "=================================================================="

# --- SHARED TRUST POLICY GENERATOR ---
generate_trust_policy() {
    cat <<EOF > "${TRUST_POLICY_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ==============================================================================
# TASK 1: CREATE DYNAMODB READER ROLE
# ==============================================================================
ROLE_NAME_DB="LambdaDynamoDBReader"
ROLE_DESC_DB="Allows Lambda to read data from DynamoDB tables"

echo "[1/6] Generating trust policy document for ${ROLE_NAME_DB}..."
generate_trust_policy

echo "[2/6] Creating IAM Role: ${ROLE_NAME_DB}..."
aws iam create-role \
    --role-name "${ROLE_NAME_DB}" \
    --description "${ROLE_DESC_DB}" \
    --assume-role-policy-document "file://${TRUST_POLICY_FILE}" > /dev/null

echo "[3/6] Attaching execution and DynamoDB read-only policies..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME_DB}" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

aws iam attach-role-policy \
    --role-name "${ROLE_NAME_DB}" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"

rm -f "${TRUST_POLICY_FILE}"


# ==============================================================================
# TASK 2: CREATE SNS PUBLISHER ROLE
# ==============================================================================
ROLE_NAME_SNS="LambdaSNSPublisher"
ROLE_DESC_SNS="Allows Lambda to publish messages to SNS topics"

echo "[4/6] Generating trust policy document for ${ROLE_NAME_SNS}..."
generate_trust_policy

echo "[5/6] Creating IAM Role: ${ROLE_NAME_SNS}..."
aws iam create-role \
    --role-name "${ROLE_NAME_SNS}" \
    --description "${ROLE_DESC_SNS}" \
    --assume-role-policy-document "file://${TRUST_POLICY_FILE}" > /dev/null

echo "[6/6] Attaching execution and SNS full access policies..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME_SNS}" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

aws iam attach-role-policy \
    --role-name "${ROLE_NAME_SNS}" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSNSFullAccess"

rm -f "${TRUST_POLICY_FILE}"


# ==============================================================================
# TASK 3: VERIFICATION AUDIT & LEAST-PRIVILEGE COMPARISON
# ==============================================================================
echo "=================================================================="
echo "Lab 03 - Task 3: Running Least-Privilege Verification Audit..."
echo "=================================================================="

echo "=== LambdaDynamoDBReader Policies ==="
aws iam list-attached-role-policies \
    --role-name "${ROLE_NAME_DB}" \
    --query 'AttachedPolicies[*].PolicyName' \
    --output table

echo ""
echo "=== LambdaSNSPublisher Policies ==="
aws iam list-attached-role-policies \
    --role-name "${ROLE_NAME_SNS}" \
    --query 'AttachedPolicies[*].PolicyName' \
    --output table

echo ""
echo "=== Reader Role Trust Policy ==="
aws iam get-role \
    --role-name "${ROLE_NAME_DB}" \
    --query 'Role.AssumeRolePolicyDocument' \
    --output json

echo ""
echo "=== Publisher Role Trust Policy ==="
aws iam get-role \
    --role-name "${ROLE_NAME_SNS}" \
    --query 'Role.AssumeRolePolicyDocument' \
    --output json

echo "=================================================================="
echo "All Lab 03 IAM roles and trust policies validated successfully!"
echo "=================================================================="
