#!/usr/bin/env bash
# ==============================================================================
# Project:      Zero-Trust Internal API from Scratch
# Module:       Lab 01 - VPC Networking & Network Isolation
# Goal:         Automate the provisioning of a secure multi-tier VPC architecture 
#               (VPC, Public/Private Subnets, IGW, Route Tables, and Internet Routing)
# ==============================================================================

set -euo pipefail

# --- 1. CONFIGURATION VARIABLES ---
AWS_REGION="us-east-1"
VPC_CIDR="10.16.0.0/16"
VPC_NAME="kloudtask-vpc"

PUBLIC_SUBNET_CIDR="10.16.1.0/24"
PUBLIC_SUBNET_NAME="public-subnet"

PRIVATE_SUBNET_CIDR="10.16.2.0/24"
PRIVATE_SUBNET_NAME="private-subnet"

AZ="us-east-1a"
IGW_NAME="kloudtask-igw"
PUBLIC_RT_NAME="public-rt"

echo "=================================================================="
echo "Starting Lab 01: Provisioning Network Boundary in ${AWS_REGION}"
echo "=================================================================="

# --- 2. CREATE VPC ---
echo "[1/7] Creating VPC: ${VPC_NAME} (${VPC_CIDR})..."
VPC_ID=$(aws ec2 create-vpc \
    --region "${AWS_REGION}" \
    --cidr-block "${VPC_CIDR}" \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC Created successfully: ${VPC_ID}"

echo "Waiting for VPC to become available..."
aws ec2 wait vpc-available \
    --region "${AWS_REGION}" \
    --vpc-ids "${VPC_ID}"

# --- 3. CREATE SUBNETS ---
echo "[2/7] Creating Public Subnet (${PUBLIC_SUBNET_NAME})..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --region "${AWS_REGION}" \
    --vpc-id "${VPC_ID}" \
    --availability-zone "${AZ}" \
    --cidr-block "${PUBLIC_SUBNET_CIDR}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PUBLIC_SUBNET_NAME}}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet Created: ${PUBLIC_SUBNET_ID}"

echo "[3/7] Creating Private Subnet (${PRIVATE_SUBNET_NAME})..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --region "${AWS_REGION}" \
    --vpc-id "${VPC_ID}" \
    --availability-zone "${AZ}" \
    --cidr-block "${PRIVATE_SUBNET_CIDR}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PRIVATE_SUBNET_NAME}}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet Created: ${PRIVATE_SUBNET_ID}"

# --- 4. CREATE & ATTACH INTERNET GATEWAY ---
echo "[4/7] Creating Internet Gateway (${IGW_NAME})..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --region "${AWS_REGION}" \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "Internet Gateway Created: ${IGW_ID}"

echo "Attaching IGW to VPC..."
aws ec2 attach-internet-gateway \
    --region "${AWS_REGION}" \
    --internet-gateway-id "${IGW_ID}" \
    --vpc-id "${VPC_ID}" > /dev/null

echo "Internet Gateway attached successfully."

# --- 5. CREATE PUBLIC ROUTE TABLE ---
echo "[5/7] Creating Public Route Table (${PUBLIC_RT_NAME})..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --region "${AWS_REGION}" \
    --vpc-id "${VPC_ID}" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PUBLIC_RT_NAME}}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Route Table Created: ${PUBLIC_RT_ID}"

# --- 6. CONFIGURE EXIT ROUTE (0.0.0.0/0) ---
echo "[6/7] Adding default internet route to Public Route Table..."
aws ec2 create-route \
    --region "${AWS_REGION}" \
    --route-table-id "${PUBLIC_RT_ID}" \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id "${IGW_ID}" > /dev/null

echo "Internet route added."

# --- 7. ASSOCIATE PUBLIC SUBNET ---
echo "[7/7] Associating Public Subnet with Public Route Table..."
ASSOCIATION_ID=$(aws ec2 associate-route-table \
    --region "${AWS_REGION}" \
    --route-table-id "${PUBLIC_RT_ID}" \
    --subnet-id "${PUBLIC_SUBNET_ID}" \
    --query 'AssociationId' \
    --output text)

echo "Association successful: ${ASSOCIATION_ID}"

# --- VERIFICATION AUDIT TRAIL ---
echo "=================================================================="
echo "Lab 01 Provisioning Complete! Running Verification Audit..."
echo "=================================================================="

aws ec2 describe-vpcs \
    --region "${AWS_REGION}" \
    --vpc-ids "${VPC_ID}" \
    --query 'Vpcs[*].{VPCId:VpcId,CIDR:CidrBlock,State:State,Name:Tags[?Key==`Name`].Value|[0]}' \
    --output table

aws ec2 describe-subnets \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[*].{SubnetId:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`].Value|[0]}' \
    --output table

aws ec2 describe-internet-gateways \
    --region "${AWS_REGION}" \
    --internet-gateway-ids "${IGW_ID}" \
    --query 'InternetGateways[0].Attachments[*].{VpcId:VpcId,State:State}' \
    --output table

echo "=================================================================="
echo "All network components validated. Ready for Lab 02!"
echo "=================================================================="
