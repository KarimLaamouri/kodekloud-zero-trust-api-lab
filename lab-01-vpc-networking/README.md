# Lab 01: VPC Networking & Network Isolation

## 🎯 Objective
Establish a secure, production-grade network boundary by reverse-engineering manual AWS Management Console (ClickOps) steps into a fully reproducible, idempotent Bash automation script. 

This lab enforces strict network isolation principles required for a Zero-Trust architecture: separating public ingress traffic from private, isolated backend resources.

---

## 🏗️ Architecture & Component Flow
The automation script provisions and wires the following resources in us-east-1:
1. Virtual Private Cloud (VPC): A dedicated network container (10.16.0.0/16) with DNS hostnames and DNS support enabled.
2. Subnet Segmentation:
   - Public Subnet (10.16.1.0/24): Designated for components requiring direct internet reachability.
   - Private Subnet (10.16.2.0/24): Strictly isolated with zero direct routes to the internet.
3. Internet Gateway (IGW): Attached to the VPC to enable inbound/outbound internet access for the public tier.
4. Public Route Table: Configured with a default gateway route (0.0.0.0/0 -> IGW) and explicitly associated exclusively with the public subnet.

---

## 📂 Directory Structure

```text
lab-01-vpc-networking/
├── README.md
└── bash/
    └── lab_execution.sh
```
---

## 🚀 Usage / How to Run

1. Navigate to the script directory:
   cd lab-01-vpc-networking/bash

2. Execute the automation script using the Bash interpreter (recommended to bypass local permission restrictions):
   bash lab_execution.sh
   *(Alternatively, if you prefer running it directly, ensure permissions are granted: chmod +x lab_execution.sh && ./lab_execution.sh)*

---

## ✅ Verification Audit
Upon successful execution, the script automatically queries AWS to output structured validation tables verifying:
- VPC state (available) and correct CIDR block allocation.
- Subnet mappings, availability zones, and association types.
- Internet Gateway attachment states.
