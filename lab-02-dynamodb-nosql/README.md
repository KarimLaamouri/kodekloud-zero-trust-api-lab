# Lab 02: NoSQL Database Management & On-Demand Capacity

## 🎯 Objective
Establish a scalable, serverless NoSQL data layer by reverse-engineering manual AWS Management Console (ClickOps) steps into a fully reproducible, robust Bash automation script. 

This lab automates DynamoDB table provisioning with strict throughput controls, dynamic data seeding, and automated billing mode migration from Provisioned to On-Demand capacity.

---

## 🏗️ Architecture & Component Flow
The automation script provisions and validates the following resources in us-east-1:
1. DynamoDB Table (`Music`): A serverless NoSQL table configured with a composite primary key:
   - Partition Key: `Artist` (String)
   - Sort Key: `SongTitle` (String)
2. Initial Throughput Provisioning: Initialized with a baseline Provisioned capacity of 1 Read Capacity Unit (RCU) and 1 Write Capacity Unit (WCU).
3. Data Seeding: Injects a structured JSON record showcasing NoSQL schema flexibility by adding an arbitrary attribute (`Album`) on the fly.
4. Capacity Mode Migration: Updates the table billing mode to On-Demand (`PAY_PER_REQUEST`), utilizing a transparent polling loop to monitor the background `UPDATING` state until the table returns to an `ACTIVE` status.

---

## 📂 Directory Structure

```text
lab-02-dynamodb-nosql/
├── README.md
└── bash/
    └── deploy_music_table.sh
```

---

## 🚀 Usage / How to Run

1. Navigate to the script directory:
   cd lab-02-dynamodb-nosql/bash

2. Execute the automation script using the Bash interpreter (recommended to bypass local permission restrictions):
   bash deploy_music_table.sh
   *(Alternatively, if you prefer running it directly, ensure permissions are granted: chmod +x deploy_music_table.sh && ./deploy_music_table.sh)*

---

## ✅ Verification Audit
Upon successful execution, the script automatically queries AWS to output structured validation tables verifying:
- Table operational status and live billing mode (`PAY_PER_REQUEST`).
- Table contents via a secure scan query verifying the seeded record attributes (`Artist`, `SongTitle`, `Album`).
