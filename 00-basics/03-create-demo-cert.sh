# Get the absolute path of the script
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source the environment variables from settings.sh in the parent directory
source "${SCRIPT_DIR}/../settings.sh"

# Use the function to execute commands
echo_and_run kubectl apply -f ./config/example-cert.yaml