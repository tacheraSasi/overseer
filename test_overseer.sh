#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}--- Starting Overseer Test Suite ---${NC}"

# 1. Check version
echo -e "\n${GREEN}[1/10] Checking version...${NC}"
overseer --version

# 2. Add a test service
echo -e "\n${GREEN}[2/10] Adding test service 'hello-task'...${NC}"
overseer add hello-task "bash -c 'while true; do echo \"Hello from Overseer at \$(date)\"; sleep 2; done'"

# 3. List services
echo -e "\n${GREEN}[3/10] Listing services...${NC}"
overseer list

# 4. Start the service
echo -e "\n${GREEN}[4/10] Starting service 'hello-task'...${NC}"
overseer start hello-task

# 5. Check status
echo -e "\n${GREEN}[5/10] Checking status of 'hello-task'...${NC}"
sleep 2 # Give it a moment to start
overseer status hello-task

# 6. Check logs
echo -e "\n${GREEN}[6/10] Checking logs of 'hello-task'...${NC}"
overseer logs hello-task

# 7. Test Environment Variables
echo -e "\n${GREEN}[7/10] Testing environment variables...${NC}"
overseer env set hello-task APP_ENV production
overseer env list hello-task

# 8. Restart service
echo -e "\n${GREEN}[8/10] Restarting service 'hello-task'...${NC}"
overseer restart hello-task
overseer status hello-task

# 9. Stop service
echo -e "\n${GREEN}[9/10] Stopping service 'hello-task'...${NC}"
overseer stop hello-task
overseer status hello-task

# 10. Remove service
echo -e "\n${GREEN}[10/10] Removing service 'hello-task'...${NC}"
overseer remove hello-task
overseer list

echo -e "\n${BLUE}--- Overseer Test Suite Completed Successfully ---${NC}"
