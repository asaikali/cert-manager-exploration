# Get the absolute path of the script
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source the environment variables from settings.sh in the parent directory
source "${SCRIPT_DIR}/../settings.sh"

echo_and_run kubectl get certificate,certificaterequest,order,challenge --all-namespaces "$@"