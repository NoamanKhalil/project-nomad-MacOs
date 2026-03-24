#!/bin/bash

# Project N.O.M.A.D. Update Script

###################################################################################################################################################################################################

# Script                | Project N.O.M.A.D. Update Script
# Version               | 1.0.1
# Author                | Crosstalk Solutions, LLC
# Website               | https://crosstalksolutions.com

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
WHITE_R='\033[39m' # Same as GRAY_R for terminals with white background.
GRAY_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Functions                                                                                             #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

check_has_sudo() {
  if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}#${RESET} User has sudo permissions.\\n"
  else
    echo "User does not have sudo permissions"
    header_red
    echo -e "${RED}#${RESET} This script requires sudo permissions to run. Please run the script with sudo.\\n"
    echo -e "${RED}#${RESET} For example: sudo bash $(basename "$0")"
    exit 1
  fi
}

check_is_bash() {
  if [[ -z "$BASH_VERSION" ]]; then
    header_red
    echo -e "${RED}#${RESET} This script requires bash to run. Please run the script using bash.\\n"
    echo -e "${RED}#${RESET} For example: bash $(basename "$0")"
    exit 1
  fi
    echo -e "${GREEN}#${RESET} This script is running in bash.\\n"
}

check_is_macos() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}#${RESET} This script is designed to run on macOS only.\\n"
    echo -e "${RED}#${RESET} Please run this script on a macOS system and try again."
    exit 1
  fi
    echo -e "${GREEN}#${RESET} This script is running on macOS.\\n"
}

get_update_confirmation(){
  read -p "This script will update Project N.O.M.A.D. and its dependencies on your machine. No data loss is expected, but you should always back up your data before proceeding. Are you sure you want to continue? (y/n): " choice
  case "$choice" in
    y|Y )
      echo -e "${GREEN}#${RESET} User chose to continue with the update."
      ;;
    n|N )
      echo -e "${RED}#${RESET} User chose not to continue with the update."
      exit 0
      ;;
    * )
      echo "Invalid Response"
      echo "User chose not to continue with the update."
      exit 0
      ;;
  esac
}

ensure_docker_installed_and_running() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}#${RESET} Docker is not installed. This is unexpected, as Project N.O.M.A.D. requires Docker to run. Did you mean to use the install script instead of the update script?"
    exit 1
  fi

  if ! docker info &>/dev/null; then
    echo -e "${RED}#${RESET} Docker is not running. Attempting to open Docker Desktop...\\n"
    open -a Docker 2>/dev/null || true
    echo -e "${RED}#${RESET} Please wait for Docker Desktop to fully start, then re-run this script."
    exit 1
  fi
}

ensure_docker_compose_file_exists() {
  if [ ! -f "${HOME}/project-nomad/compose.yml" ]; then
    echo -e "${RED}#${RESET} compose.yml file not found. Please ensure it exists at ${HOME}/project-nomad/compose.yml."
    exit 1
  fi
}

force_recreate() {
  echo -e "${YELLOW}#${RESET} Pulling the latest Docker images..."
  if ! docker compose -p project-nomad -f ${HOME}/project-nomad/compose.yml pull; then
    echo -e "${RED}#${RESET} Failed to pull the latest Docker images. Please check your network connection and the Docker registry status, then try again."
    exit 1
  fi
  
  echo -e "${YELLOW}#${RESET} Forcing recreation of containers..."
  if ! docker compose -p project-nomad -f ${HOME}/project-nomad/compose.yml up -d --force-recreate; then
    echo -e "${RED}#${RESET} Failed to recreate containers. Please check the Docker logs for more details."
    exit 1
  fi
}

get_local_ip() {
  local active_iface
  active_iface=$(route get default 2>/dev/null | awk '/interface:/{print $2}')
  if [[ -n "$active_iface" ]]; then
    local_ip_address=$(ipconfig getifaddr "$active_iface" 2>/dev/null)
  fi
  if [[ -z "$local_ip_address" ]]; then
    for iface in en0 en1 en2 en3; do
      local_ip_address=$(ipconfig getifaddr "$iface" 2>/dev/null)
      [[ -n "$local_ip_address" ]] && break
    done
  fi
  if [[ -z "$local_ip_address" ]]; then
    local_ip_address="127.0.0.1"
    echo -e "${YELLOW}#${RESET} Could not determine LAN IP — defaulting to 127.0.0.1 (localhost only).\\n"
  fi
}

success_message() {
  echo -e "${GREEN}#${RESET} Project N.O.M.A.D installation completed successfully!\\n"
  echo -e "${GREEN}#${RESET} Installation files are located at ${HOME}/project-nomad\\n\n"
  echo -e "${GREEN}#${RESET} Project N.O.M.A.D's Command Center should automatically start whenever your device reboots. However, if you need to start it manually, you can always do so by running: ${WHITE_R}${NOMAD_DIR}/start_nomad.sh${RESET}\\n"
  echo -e "${GREEN}#${RESET} You can now access the management interface at http://localhost:8080 or http://${local_ip_address}:8080\\n"
  echo -e "${GREEN}#${RESET} Thank you for supporting Project N.O.M.A.D!\\n"
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Main Script                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Pre-flight checks
check_is_macos
check_is_bash
check_has_sudo

# Main update
get_update_confirmation
ensure_docker_installed_and_running
ensure_docker_compose_file_exists
force_recreate
get_local_ip
success_message
