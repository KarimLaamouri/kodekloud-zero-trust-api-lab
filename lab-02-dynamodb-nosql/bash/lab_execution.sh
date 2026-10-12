#!/usr/bin/env bash
# ==============================================================================
# Project:     Zero-Trust Internal API from Scratch
# Module:      Lab 02 - NoSQL Database Management & On-Demand Capacity
# Goal:        Automate the provisioning of a DynamoDB table with provisioned 
#              capacity, seed initial music records, update to on-demand billing,
#              and run compliance verification audits.
# ==============================================================================

set -euo pipefail

# --- 1. CONFIGURATION VARIABLES ---
AWS_REGION="us-east-1"
TABLE_NAME="Music"

echo "=================================================================="
echo "Starting Lab 02: DynamoDB Deployment in ${AWS_REGION}"
echo "=================================================================="

# --- 2. CREATE TABLE (PROVISIONED CAPACITY) ---
echo "[1/3] Creating DynamoDB table: ${TABLE_NAME} (Provisioned 1 RCU / 1 WCU)..."
aws dynamodb create-table \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=Artist,AttributeType=S AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 > /dev/null

echo "Waiting for table status to change from Creating to Active..."
aws dynamodb wait table-exists \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}"

echo "Table '${TABLE_NAME}' is now ACTIVE."

# --- 3. SEED ITEM ---
echo "[2/3] Adding initial record to ${TABLE_NAME}..."
aws dynamodb put-item \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}" \
    --item '{"Artist": {"S": "The Beatles"}, "SongTitle": {"S": "Let It Be"}, "Album": {"S": "Let It Be"}}' > /dev/null

echo "Record inserted successfully."

# --- 4. UPDATE CAPACITY MODE (ON-DEMAND) ---
echo "[3/3] Updating table billing mode to On-Demand (PAY_PER_REQUEST)..."
aws dynamodb update-table \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}" \
    --billing-mode PAY_PER_REQUEST > /dev/null

echo "Waiting for table update to complete..."
while true; do
    STATUS=$(aws dynamodb describe-table --region "${AWS_REGION}" --table-name "${TABLE_NAME}" --query 'Table.TableStatus' --output text 2>/dev/null || echo "UPDATING")
    if [ "$STATUS" = "ACTIVE" ]; then
        break
    fi
    echo -n "."
    sleep 3
done
echo ""
echo "Capacity update completed successfully."

# --- VERIFICATION AUDIT TRAIL ---
echo "=================================================================="
echo "Lab 02 Provisioning Complete! Running Verification Audit..."
echo "=================================================================="

aws dynamodb describe-table \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}" \
    --query 'Table.{TableName:TableName, Status:TableStatus, BillingMode:BillingModeSummary.BillingMode}' \
    --output table

aws dynamodb scan \
    --region "${AWS_REGION}" \
    --table-name "${TABLE_NAME}" \
    --query "Items[*].{Artist:Artist.S, SongTitle:SongTitle.S, Album:Album.S}" \
    --output table

echo "=================================================================="
echo "All DynamoDB components validated. Ready for Lab 03!"
echo "=================================================================="
