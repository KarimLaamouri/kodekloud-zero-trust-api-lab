
#!/usr/bin/env bash
# ==============================================================================
# Project:     Zero-Trust Internal API from Scratch
# Module:      Lab 04 - Serverless Lambda CLI Deployment & Execution Role Foundations
# Goal:        Automate Lambda deployment, environment variables, code updates, 
#              test invocations, dynamic CloudWatch metrics via statistics, and logs.
# ==============================================================================

set -euo pipefail

# --- 1. CONFIGURATION VARIABLES ---
AWS_REGION="us-east-1"
FUNCTION_NAME="DataProcessor"
ROLE_NAME="lambda_execution_role"
ROLE_DESC="Custom execution role for Lambda CLI deployment"
RUNTIME="python3.14"
TRUST_POLICY_FILE="trust-policy.json"
ZIP_FILE="function.zip"
SOURCE_FILE="index.py"
RESPONSE_FILE="response.json"

echo "=================================================================="
echo "Starting Lab 04: Step-by-Step Lambda CLI Deployment & Monitoring"
echo "=================================================================="

# --- DYNAMIC ACCOUNT ID RESOLUTION ---
echo "[1/12] Fetching active AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "      -> Target Account: ${AWS_ACCOUNT_ID}"
echo "      -> Resolved Role ARN: ${ROLE_ARN}"

# --- TRUST POLICY GENERATOR ---
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
# TASK 1: CREATE CUSTOM IAM EXECUTION ROLE
# ==============================================================================
echo "[2/12] Generating trust policy document..."
generate_trust_policy

echo "[3/12] Creating IAM Role: ${ROLE_NAME}..."
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
    echo "      -> Role ${ROLE_NAME} already exists. Skipping creation."
else
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --description "${ROLE_DESC}" \
        --assume-role-policy-document "file://${TRUST_POLICY_FILE}" > /dev/null
    echo "      -> Role created successfully."
fi

echo "[4/12] Attaching AWSLambdaBasicExecutionRole policy..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

rm -f "${TRUST_POLICY_FILE}"

# Wait for IAM eventual consistency propagation
echo "      -> Waiting for IAM role propagation across AWS regions..."
sleep 10

# ==============================================================================
# TASK 2: DEPLOY INITIAL BASIC "HELLO WORLD" FUNCTION
# ==============================================================================
echo "[5/12] Generating initial Hello World source code (${SOURCE_FILE})..."
cat <<EOF > "${SOURCE_FILE}"
def handler(event, context):
    return {
        "statusCode": 200,
        "body": "Hello from CLI-deployed Lambda!"
    }
EOF

echo "[6/12] Creating deployment package (${ZIP_FILE})..."
zip -q "${ZIP_FILE}" "${SOURCE_FILE}"

echo "[7/12] Creating Lambda Function (${FUNCTION_NAME}) with basic handler..."
if aws lambda get-function --function-name "${FUNCTION_NAME}" >/dev/null 2>&1; then
    echo "      -> Function ${FUNCTION_NAME} already exists. Updating code..."
    aws lambda update-function-code \
        --function-name "${FUNCTION_NAME}" \
        --zip-file "fileb://${ZIP_FILE}" > /dev/null
else
    aws lambda create-function \
        --function-name "${FUNCTION_NAME}" \
        --runtime "${RUNTIME}" \
        --role "${ROLE_ARN}" \
        --handler "index.handler" \
        --zip-file "fileb://${ZIP_FILE}" > /dev/null
fi

echo "      -> Waiting for function to become active..."
aws lambda wait function-active --function-name "${FUNCTION_NAME}"

# ==============================================================================
# TASK 3: CONFIGURE ENVIRONMENT VARIABLES
# ==============================================================================
echo "[8/12] Configuring function environment variables..."
aws lambda update-function-configuration \
    --function-name "${FUNCTION_NAME}" \
    --environment "Variables={ENVIRONMENT=production,MAX_RECORDS=1000}" > /dev/null

echo "      -> Waiting for configuration updates to apply..."
aws lambda wait function-updated --function-name "${FUNCTION_NAME}"

# ==============================================================================
# TASK 4: UPDATE CODE TO DATA PROCESSOR LOGIC & INVOKE
# ==============================================================================
echo "[9/12] Updating function code to data processor handler logic..."
cat <<EOF > "${SOURCE_FILE}"
import json
import os

def lambda_handler(event, context):
    env = os.environ.get('ENVIRONMENT', 'unknown')
    max_records = os.environ.get('MAX_RECORDS', '0')

    data = event.get('data', [])
    record_count = len(data)

    return {
        'statusCode': 200,
        'environment': env,
        'max_records': max_records,
        'records_received': record_count,
        'message': f'Processed {record_count} records in {env}'
    }
EOF

zip -q "${ZIP_FILE}" "${SOURCE_FILE}"

aws lambda update-function-code \
    --function-name "${FUNCTION_NAME}" \
    --zip-file "fileb://${ZIP_FILE}" > /dev/null

aws lambda update-function-configuration \
    --function-name "${FUNCTION_NAME}" \
    --handler "index.lambda_handler" > /dev/null

echo "      -> Waiting for final code & handler updates to stabilize..."
aws lambda wait function-updated --function-name "${FUNCTION_NAME}"

# Cleanup local build artifacts
rm -f "${SOURCE_FILE}" "${ZIP_FILE}"

echo "[10/12] Invoking Lambda function multiple times to generate metrics..."
for i in {1..3}; do
    aws lambda invoke \
        --function-name "${FUNCTION_NAME}" \
        --cli-binary-format raw-in-base64-out \
        --payload '{"data": [1, 2, 3, 4, 5]}' \
        "${RESPONSE_FILE}" > /dev/null
    echo "      -> Invocation $i complete."
done

# ==============================================================================
# TASK 5: CLOUDWATCH METRICS & LOG AUDIT
# ==============================================================================
echo "[11/12] Waiting 20 seconds for CloudWatch metrics aggregation..."
sleep 20

START_TIME=$(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

INVOCATIONS=$(aws cloudwatch get-metric-statistics \
    --namespace "AWS/Lambda" \
    --metric-name "Invocations" \
    --dimensions Name=FunctionName,Value="${FUNCTION_NAME}" \
    --start-time "${START_TIME}" \
    --end-time "${END_TIME}" \
    --period 300 \
    --statistics Sum \
    --query "Datapoints[0].Sum" --output text)

DURATION=$(aws cloudwatch get-metric-statistics \
    --namespace "AWS/Lambda" \
    --metric-name "Duration" \
    --dimensions Name=FunctionName,Value="${FUNCTION_NAME}" \
    --start-time "${START_TIME}" \
    --end-time "${END_TIME}" \
    --period 300 \
    --statistics Average \
    --query "Datapoints[0].Average" --output text)

ERRORS=$(aws cloudwatch get-metric-statistics \
    --namespace "AWS/Lambda" \
    --metric-name "Errors" \
    --dimensions Name=FunctionName,Value="${FUNCTION_NAME}" \
    --start-time "${START_TIME}" \
    --end-time "${END_TIME}" \
    --period 300 \
    --statistics Sum \
    --query "Datapoints[0].Sum" --output text)

THROTTLES=$(aws cloudwatch get-metric-statistics \
    --namespace "AWS/Lambda" \
    --metric-name "Throttles" \
    --dimensions Name=FunctionName,Value="${FUNCTION_NAME}" \
    --start-time "${START_TIME}" \
    --end-time "${END_TIME}" \
    --period 300 \
    --statistics Sum \
    --query "Datapoints[0].Sum" --output text)

# Normalize empty, "None", or null metrics to safe defaults
[ "${INVOCATIONS}" = "None" ] || [ -z "${INVOCATIONS}" ] && INVOCATIONS="0"
[ "${DURATION}" = "None" ] || [ -z "${DURATION}" ] && DURATION="0.0"
[ "${ERRORS}" = "None" ] || [ -z "${ERRORS}" ] && ERRORS="0"
[ "${THROTTLES}" = "None" ] || [ -z "${THROTTLES}" ] && THROTTLES="0"

echo "[12/12] Retrieving latest CloudWatch log stream events..."
LOG_GROUP="/aws/lambda/${FUNCTION_NAME}"
LATEST_STREAM=$(aws logs describe-log-streams \
    --log-group-name "${LOG_GROUP}" \
    --order-by LastEventTime \
    --descending \
    --limit 1 \
    --query 'logStreams[0].logStreamName' \
    --output text 2>/dev/null || echo "None")

# ==============================================================================
# VERIFICATION AUDIT & REPORTING
# ==============================================================================
echo "=================================================================="
echo "Lab 04 - Verification Audit & Test Results"
echo "=================================================================="

echo "=== Last Lambda Function Invocation Response (${RESPONSE_FILE}) ==="
cat "${RESPONSE_FILE}"
echo ""
rm -f "${RESPONSE_FILE}"

echo ""
echo "=== CloudWatch Performance Metrics (Last 15 Minutes) ==="
echo " Invocations : ${INVOCATIONS} calls"
echo " Avg Duration: ${DURATION} ms"
echo " Errors      : ${ERRORS} failures"
echo " Throttles   : ${THROTTLES} throttled"

echo ""
if [ "${LATEST_STREAM}" != "None" ] && [ -n "${LATEST_STREAM}" ]; then
    echo "=== Log Events from Stream: ${LATEST_STREAM} ==="
    aws logs get-log-events \
        --log-group-name "${LOG_GROUP}" \
        --log-stream-name "${LATEST_STREAM}" \
        --query 'events[*].message' \
        --output text
else
    echo "=== CloudWatch Log Streams ==="
    echo "No log streams available yet."
fi

echo ""
echo "=== Lambda Function State & Configuration ==="
aws lambda get-function \
    --function-name "${FUNCTION_NAME}" \
    --query 'Configuration.{FunctionName: FunctionName, State: State, Runtime: Runtime, Role: Role, Handler: Handler}' \
    --output table

echo ""
echo "=== Function Environment Variables ==="
aws lambda get-function-configuration \
    --function-name "${FUNCTION_NAME}" \
    --query "Environment.Variables" \
    --output table

echo ""
echo "=== Attached Role Policies for ${ROLE_NAME} ==="
aws iam list-attached-role-policies \
    --role-name "${ROLE_NAME}" \
    --query 'AttachedPolicies[*].PolicyName' \
    --output table

echo "=================================================================="
echo "Lab 04 complete: Role, deployment, configuration, test, metrics & logs validated!"
echo "=================================================================="
