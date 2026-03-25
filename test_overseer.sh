#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

OVERSEER_UID=1000

# Ensure we are running as the 'overseer' user for the rest of the script
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${BLUE}Root setup: Initializing environment...${NC}"
    
    # 1. Wait for system bus
    echo -e "${BLUE}Waiting for system bus...${NC}"
    timeout 15s bash -c "until [ -S /run/dbus/system_bus_socket ]; do sleep 1; done" || { echo -e "${RED}System bus timeout${NC}"; exit 1; }

    # 2. Force create the user runtime directory
    echo -e "${BLUE}Setting up /run/user/$OVERSEER_UID...${NC}"
    mkdir -p "/run/user/$OVERSEER_UID"
    chown overseer:overseer "/run/user/$OVERSEER_UID"
    chmod 700 "/run/user/$OVERSEER_UID"

    # 3. Start the user manager service
    echo -e "${BLUE}Starting systemd user manager for UID $OVERSEER_UID...${NC}"
    systemctl start "user@$OVERSEER_UID.service" || echo -e "${RED}Warning: Could not start user@$OVERSEER_UID.service directly, continuing...${NC}"

    # 4. Enable lingering as a backup
    loginctl enable-linger overseer || true

    echo -e "${BLUE}Restarting script as 'overseer' user...${NC}"
    export XDG_RUNTIME_DIR="/run/user/$OVERSEER_UID"
    exec sudo -u overseer -E "$0" "$@"
fi

# Now we are the 'overseer' user
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# Check if user manager is reachable
echo -e "${BLUE}Checking systemd user manager connectivity...${NC}"
if ! systemctl --user status > /dev/null 2>&1; then
    echo -e "${RED}Error: systemctl --user is not reachable.${NC}"
    echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    ls -la "$XDG_RUNTIME_DIR"
    exit 1
fi

echo -e "${BLUE}--- Starting Overseer Test Suite (User: $(whoami)) ---${NC}"

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
sleep 3
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
