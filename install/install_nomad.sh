#!/bin/bash

# Project N.O.M.A.D. Installation Script

###################################################################################################################################################################################################

# Script                | Project N.O.M.A.D. Installation Script
# Version               | 1.0.0
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
#                                                                                  Constants & Variables                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

WHIPTAIL_TITLE="Project N.O.M.A.D Installation"
NOMAD_DIR="${HOME}/project-nomad"
MANAGEMENT_COMPOSE_FILE_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/management_compose.yaml"
ENTRYPOINT_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/entrypoint.sh"
SIDECAR_UPDATER_DOCKERFILE_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/sidecar-updater/Dockerfile"
SIDECAR_UPDATER_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/sidecar-updater/update-watcher.sh"
START_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/start_nomad.sh"
STOP_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/stop_nomad.sh"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/update_nomad.sh"
WAIT_FOR_IT_SCRIPT_URL="https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh"

script_option_debug='true'
accepted_terms='false'
local_ip_address=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Functions                                                                                             #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header() {
  if [[ "${script_option_debug}" != 'true' ]]; then clear; clear; fi
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  if [[ "${script_option_debug}" != 'true' ]]; then clear; clear; fi
  echo -e "${RED}#########################################################################${RESET}\\n"
}

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
    header_red
    echo -e "${RED}#${RESET} This script is designed to run on macOS only.\\n"
    echo -e "${RED}#${RESET} Please run this script on a macOS system and try again."
    exit 1
  fi
    echo -e "${GREEN}#${RESET} This script is running on macOS.\\n"
}

ensure_dependencies_installed() {
  local missing_deps=()

  # Check for curl
  if ! command -v curl &> /dev/null; then
    missing_deps+=("curl")
  fi

  # Check for whiptail (used for dialogs, though not currently active)
  # if ! command -v whiptail &> /dev/null; then
  #   missing_deps+=("whiptail")
  # fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo -e "${YELLOW}#${RESET} Installing required dependencies: ${missing_deps[*]}...\\n"

    if ! command -v brew &> /dev/null; then
      echo -e "${RED}#${RESET} Homebrew is not installed. Please install it from https://brew.sh and try again."
      exit 1
    fi

    brew install "${missing_deps[@]}"

    # Verify installation
    for dep in "${missing_deps[@]}"; do
      if ! command -v "$dep" &> /dev/null; then
        echo -e "${RED}#${RESET} Failed to install $dep. Please install it manually and try again."
        exit 1
      fi
    done
    echo -e "${GREEN}#${RESET} Dependencies installed successfully.\\n"
  else
    echo -e "${GREEN}#${RESET} All required dependencies are already installed.\\n"
  fi
}

check_is_debug_mode(){
  # Check if the script is being run in debug mode
  if [[ "${script_option_debug}" == 'true' ]]; then
    echo -e "${YELLOW}#${RESET} Debug mode is enabled, the script will not clear the screen...\\n"
  else
    clear; clear
  fi
}

generateRandomPass() {
  local length="${1:-32}"  # Default to 32
  local password
  
  # Generate random password using /dev/urandom
  password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length")
  
  echo "$password"
}

ensure_docker_installed() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}#${RESET} Docker Desktop is not installed.\\n"
    echo -e "${RED}#${RESET} Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop/"
    echo -e "${RED}#${RESET} After installing, open Docker Desktop, wait for it to finish starting, then re-run this script."
    exit 1
  else
    echo -e "${GREEN}#${RESET} Docker is installed.\\n"

    # Check if Docker daemon is running
    if ! docker info &>/dev/null; then
      echo -e "${YELLOW}#${RESET} Docker is installed but not running. Attempting to open Docker Desktop...\\n"
      open -a Docker 2>/dev/null || true
      echo -e "${RED}#${RESET} Please wait for Docker Desktop to fully start, then re-run this script."
      exit 1
    else
      echo -e "${GREEN}#${RESET} Docker is running.\\n"
    fi
  fi
}

setup_apple_silicon_gpu() {
  # This function is informational only — Apple Silicon uses Metal natively via Ollama
  # No additional toolkit installation is required on macOS

  echo -e "${YELLOW}#${RESET} Checking for Apple Silicon GPU (Metal)...\\n"

  local chip
  chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")

  if [[ "$chip" == *"Apple"* ]]; then
    echo -e "${GREEN}#${RESET} Apple Silicon detected: ${chip}\\n"
    echo -e "${GREEN}#${RESET} Metal GPU acceleration is available natively via Ollama — no additional setup required.\\n"
    echo -e "${YELLOW}#${RESET} For best AI performance, allocate at least 8GB to Docker Desktop:\\n"
    echo -e "${YELLOW}#${RESET}   Docker Desktop → Settings → Resources → Memory\\n"
  else
    echo -e "${YELLOW}#${RESET} Intel Mac detected: ${chip}\\n"
    echo -e "${YELLOW}#${RESET} GPU acceleration via Metal may be limited on Intel Macs.\\n"
    echo -e "${YELLOW}#${RESET} The AI assistant will run in CPU-only mode.\\n"
  fi
}

get_install_confirmation(){
  read -p "This script will install/update Project N.O.M.A.D. and its dependencies on your machine. Are you sure you want to continue? (y/N): " choice
  case "$choice" in
    y|Y )
      echo -e "${GREEN}#${RESET} User chose to continue with the installation."
      ;;
    * )
      echo "User chose not to continue with the installation."
      exit 0
      ;;
  esac
}

accept_terms() {
  printf "\n\n"
  echo "License Agreement & Terms of Use"
  echo "__________________________"
  printf "\n\n"
  echo "Project N.O.M.A.D. is licensed under the Apache License 2.0. The full license can be found at https://www.apache.org/licenses/LICENSE-2.0 or in the LICENSE file of this repository."
  printf "\n"
  echo "By accepting this agreement, you acknowledge that you have read and understood the terms and conditions of the Apache License 2.0 and agree to be bound by them while using Project N.O.M.A.D."
  echo -e "\n\n"
  read -p "I have read and accept License Agreement & Terms of Use (y/N)? " choice
  case "$choice" in
    y|Y )
      accepted_terms='true'
      ;;
    * )
      echo "License Agreement & Terms of Use not accepted. Installation cannot continue."
      exit 1
      ;;
  esac
}

create_nomad_directory(){
  # Ensure the main installation directory exists
  if [[ ! -d "$NOMAD_DIR" ]]; then
    echo -e "${YELLOW}#${RESET} Creating directory for Project N.O.M.A.D at $NOMAD_DIR...\\n"
    sudo mkdir -p "$NOMAD_DIR"
    sudo chown "$(whoami):$(whoami)" "$NOMAD_DIR"

    echo -e "${GREEN}#${RESET} Directory created successfully.\\n"
  else
    echo -e "${GREEN}#${RESET} Directory $NOMAD_DIR already exists.\\n"
  fi

  # Also ensure the directory has a /storage/logs/ subdirectory
  sudo mkdir -p "${NOMAD_DIR}/storage/logs"

  # Create a admin.log file in the logs directory
  sudo touch "${NOMAD_DIR}/storage/logs/admin.log"
}

download_management_compose_file() {
  local compose_file_path="${NOMAD_DIR}/compose.yml"

  echo -e "${YELLOW}#${RESET} Downloading docker-compose file for management...\\n"
  if ! curl -fsSL "$MANAGEMENT_COMPOSE_FILE_URL" -o "$compose_file_path"; then
    echo -e "${RED}#${RESET} Failed to download the docker compose file. Please check the URL and try again."
    exit 1
  fi
  echo -e "${GREEN}#${RESET} Docker compose file downloaded successfully to $compose_file_path.\\n"

  local app_key=$(generateRandomPass)
  local db_root_password=$(generateRandomPass)
  local db_user_password=$(generateRandomPass)

  # Inject dynamic env values into the compose file
  echo -e "${YELLOW}#${RESET} Configuring docker-compose file env variables...\\n"
  sed -i '' "s|URL=replaceme|URL=http://${local_ip_address}:8080|g" "$compose_file_path"
  sed -i '' "s|APP_KEY=replaceme|APP_KEY=${app_key}|g" "$compose_file_path"

  sed -i '' "s|DB_PASSWORD=replaceme|DB_PASSWORD=${db_user_password}|g" "$compose_file_path"
  sed -i '' "s|MYSQL_ROOT_PASSWORD=replaceme|MYSQL_ROOT_PASSWORD=${db_root_password}|g" "$compose_file_path"
  sed -i '' "s|MYSQL_PASSWORD=replaceme|MYSQL_PASSWORD=${db_user_password}|g" "$compose_file_path"

  # Detect Apple Silicon chip model (e.g. "Apple M3 Pro") for hardware display in benchmark
  local apple_chip
  apple_chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
  if [[ -n "$apple_chip" ]]; then
    sed -i '' "s|APPLE_CHIP_MODEL=replaceme_apple_chip|APPLE_CHIP_MODEL=${apple_chip}|g" "$compose_file_path"
  else
    # Not Apple Silicon — remove the placeholder line entirely
    sed -i '' "/APPLE_CHIP_MODEL=replaceme_apple_chip/d" "$compose_file_path"
  fi

  echo -e "${GREEN}#${RESET} Docker compose file configured successfully.\\n"
}

download_wait_for_it_script() {
  local wait_for_it_script_path="${NOMAD_DIR}/wait-for-it.sh"

  echo -e "${YELLOW}#${RESET} Downloading wait-for-it script...\\n"
  if ! curl -fsSL "$WAIT_FOR_IT_SCRIPT_URL" -o "$wait_for_it_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the wait-for-it script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$wait_for_it_script_path"
  echo -e "${GREEN}#${RESET} wait-for-it script downloaded successfully to $wait_for_it_script_path.\\n"
}

download_entrypoint_script() {
  local entrypoint_script_path="${NOMAD_DIR}/entrypoint.sh"

  echo -e "${YELLOW}#${RESET} Downloading entrypoint script...\\n"
  if ! curl -fsSL "$ENTRYPOINT_SCRIPT_URL" -o "$entrypoint_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the entrypoint script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$entrypoint_script_path"
  echo -e "${GREEN}#${RESET} entrypoint script downloaded successfully to $entrypoint_script_path.\\n"
}

download_sidecar_files() {
  # Create sidecar-updater directory if it doesn't exist
  if [[ ! -d "${NOMAD_DIR}/sidecar-updater" ]]; then
    sudo mkdir -p "${NOMAD_DIR}/sidecar-updater"
    sudo chown "$(whoami):$(whoami)" "${NOMAD_DIR}/sidecar-updater"
  fi

  local sidecar_dockerfile_path="${NOMAD_DIR}/sidecar-updater/Dockerfile"
  local sidecar_script_path="${NOMAD_DIR}/sidecar-updater/update-watcher.sh"

  echo -e "${YELLOW}#${RESET} Downloading sidecar updater Dockerfile...\\n"
  if ! curl -fsSL "$SIDECAR_UPDATER_DOCKERFILE_URL" -o "$sidecar_dockerfile_path"; then
    echo -e "${RED}#${RESET} Failed to download the sidecar updater Dockerfile. Please check the URL and try again."
    exit 1
  fi
  echo -e "${GREEN}#${RESET} Sidecar updater Dockerfile downloaded successfully to $sidecar_dockerfile_path.\\n"

  echo -e "${YELLOW}#${RESET} Downloading sidecar updater script...\\n"
  if ! curl -fsSL "$SIDECAR_UPDATER_SCRIPT_URL" -o "$sidecar_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the sidecar updater script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$sidecar_script_path"
  echo -e "${GREEN}#${RESET} Sidecar updater script downloaded successfully to $sidecar_script_path.\\n"
}

download_helper_scripts() {
  local start_script_path="${NOMAD_DIR}/start_nomad.sh"
  local stop_script_path="${NOMAD_DIR}/stop_nomad.sh"
  local update_script_path="${NOMAD_DIR}/update_nomad.sh"

  echo -e "${YELLOW}#${RESET} Downloading helper scripts...\\n"
  if ! curl -fsSL "$START_SCRIPT_URL" -o "$start_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the start script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$start_script_path"

  if ! curl -fsSL "$STOP_SCRIPT_URL" -o "$stop_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the stop script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$stop_script_path"

  if ! curl -fsSL "$UPDATE_SCRIPT_URL" -o "$update_script_path"; then
    echo -e "${RED}#${RESET} Failed to download the update script. Please check the URL and try again."
    exit 1
  fi
  chmod +x "$update_script_path"

  echo -e "${GREEN}#${RESET} Helper scripts downloaded successfully to $start_script_path, $stop_script_path, and $update_script_path.\\n"
}

start_management_containers() {
  echo -e "${YELLOW}#${RESET} Starting management containers using docker compose...\\n"
  if ! sudo docker compose -p project-nomad -f "${NOMAD_DIR}/compose.yml" up -d; then
    echo -e "${RED}#${RESET} Failed to start management containers. Please check the logs and try again."
    exit 1
  fi
  echo -e "${GREEN}#${RESET} Management containers started successfully.\\n"
}

get_local_ip() {
  local_ip_address=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || hostname)
  if [[ -z "$local_ip_address" ]]; then
    echo -e "${RED}#${RESET} Unable to determine local IP address. Please check your network configuration."
    exit 1
  fi
}
verify_gpu_setup() {
  # This function only displays GPU setup status and is completely non-blocking
  # It never exits or returns error codes - purely informational

  echo -e "\\n${YELLOW}#${RESET} GPU Setup Verification\\n"
  echo -e "${YELLOW}===========================================${RESET}\\n"

  local chip
  chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")

  if [[ "$chip" == *"Apple"* ]]; then
    echo -e "${GREEN}✓${RESET} Apple Silicon detected: ${chip}\\n"
    echo -e "${GREEN}✓${RESET} Metal GPU acceleration available via Ollama\\n"

    # Report Docker Desktop memory allocation
    local docker_memory
    docker_memory=$(docker info --format '{{.MemTotal}}' 2>/dev/null)
    if [[ -n "$docker_memory" ]]; then
      local mem_gb=$(( docker_memory / 1024 / 1024 / 1024 ))
      if [[ "$mem_gb" -ge 8 ]]; then
        echo -e "${GREEN}✓${RESET} Docker Desktop memory: ${mem_gb}GB (sufficient)\\n"
      else
        echo -e "${YELLOW}○${RESET} Docker Desktop memory: ${mem_gb}GB (recommended: 8GB+)\\n"
        echo -e "${YELLOW}#${RESET} Tip: Open Docker Desktop → Settings → Resources → Memory to increase allocation.\\n"
      fi
    fi
  else
    echo -e "${YELLOW}○${RESET} Intel Mac detected: ${chip}\\n"
    echo -e "${YELLOW}○${RESET} GPU acceleration via Metal may be limited — AI will run in CPU-only mode\\n"
  fi

  echo -e "${YELLOW}===========================================${RESET}\\n"

  if [[ "$chip" == *"Apple"* ]]; then
    echo -e "${GREEN}#${RESET} GPU acceleration is available! The AI Assistant will use Apple Silicon Metal.\\n"
  else
    echo -e "${YELLOW}#${RESET} GPU acceleration not available on Intel Mac. The AI Assistant will run in CPU-only mode.\\n"
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
ensure_dependencies_installed
check_is_debug_mode

# Main install
get_install_confirmation
accept_terms
ensure_docker_installed
setup_apple_silicon_gpu
get_local_ip
create_nomad_directory
download_wait_for_it_script
download_entrypoint_script
download_sidecar_files
download_helper_scripts
download_management_compose_file
start_management_containers
verify_gpu_setup
success_message

# free_space_check() {
#   if [[ "$(df -B1 / | awk 'NR==2{print $4}')" -le '5368709120' ]]; then
#     header_red
#     echo -e "${YELLOW}#${RESET} You only have $(df -B1 / | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/\"... \\n"
#     while true; do
#       read -rp $'\033[39m#\033[0m Do you want to proceed with running the script? (y/N) ' yes_no
#       case "$yes_no" in
#          [Nn]*|"")
#             free_space_check_response="Cancel script"
#             free_space_check_date="$(date +%s)"
#             echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the script again..."
#             cancel_script
#             break;;
#          [Yy]*)
#             free_space_check_response="Proceed at own risk"
#             free_space_check_date="$(date +%s)"
#             echo -e "${YELLOW}#${RESET} OK... Proceeding with the script.. please note that failures may occur due to not enough disk space... \\n"; sleep 10
#             break;;
#          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
#       esac
#     done
#     if [[ -n "$(command -v jq)" ]]; then
#       if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" && -e "${eus_dir}/db/db.json" ]]; then
#         jq '.scripts."'"${script_name}"'" += {"warnings": {"low-free-disk-space": {"response": "'"${free_space_check_response}"'", "detected-date": "'"${free_space_check_date}"'"}}}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
#       else
#         jq '.scripts."'"${script_name}"'" = (.scripts."'"${script_name}"'" | . + {"warnings": {"low-free-disk-space": {"response": "'"${free_space_check_response}"'", "detected-date": "'"${free_space_check_date}"'"}}})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
#       fi
#       eus_database_move
#     fi
#   fi
# }
