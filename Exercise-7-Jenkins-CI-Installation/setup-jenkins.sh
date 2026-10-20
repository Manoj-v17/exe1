#!/bin/bash
# Jenkins Docker Setup Script
# Exercise 7: Introduction to CI and Jenkins Installation

echo "=========================================="
echo "  ZAPPTTO Jenkins CI Setup"
echo "=========================================="

# Step 1: Pull and run Jenkins LTS container
echo ""
echo "[STEP 1] Launching Jenkins LTS container..."
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  jenkins/jenkins:lts

echo "[INFO] Jenkins container started."

# Step 2: Wait for Jenkins to initialize
echo ""
echo "[STEP 2] Waiting 30 seconds for Jenkins to initialize..."
sleep 30

# Step 3: Verify container is running
echo ""
echo "[STEP 3] Verifying container status..."
docker ps --filter "name=jenkins"

# Step 4: Retrieve initial admin password
echo ""
echo "[STEP 4] Retrieving Jenkins initial admin password..."
echo "-------------------------------------------"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
echo "-------------------------------------------"

echo ""
echo "[DONE] Open http://localhost:8080 in your browser and enter the password above."
echo "       Select 'Install Suggested Plugins' on the setup wizard."
