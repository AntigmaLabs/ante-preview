#!/bin/bash
set -e

# Ante installer script with SHA256 and size verification
# Usage: curl -fsSL <install-script-url> | bash -s -- "<manifest-url>"
# Or: ./install.sh "<manifest-url>"

MANIFEST_URL="${1}"
BINARY_NAME="${BINARY_NAME:-ante}"
NO_MODIFY_PATH="${NO_MODIFY_PATH:-false}"

# Install to user's home directory (no sudo required)
INSTALL_DIR="$HOME/.${BINARY_NAME}/bin"

# Temp files to track for cleanup
TEMP_FILES=()
TEMP_DIRS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MUTED='\033[0;2m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    cleanup
    exit 1
}

# Cleanup function for temporary files
cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null || true
    done
    for d in "${TEMP_DIRS[@]}"; do
        rm -rf "$d" 2>/dev/null || true
    done
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Downloader selection
DOWNLOADER=""
select_downloader() {
    if command -v curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
    else
        error "Either curl or wget is required but neither is installed"
    fi
}

# Download function that works with both curl and wget
download_file() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOADER" = "curl" ]; then
        if [ -n "$output" ]; then
            curl -fsSL -o "$output" "$url"
        else
            curl -fsSL "$url"
        fi
    elif [ "$DOWNLOADER" = "wget" ]; then
        if [ -n "$output" ]; then
            wget -q -O "$output" "$url"
        else
            wget -q -O - "$url"
        fi
    else
        return 1
    fi
}

# Check if required commands are available
check_requirements() {
    select_downloader

    if ! command -v tar &> /dev/null; then
        error "tar is required but not installed"
    fi

    # Check for sha256sum or shasum
    if ! command -v sha256sum &> /dev/null && ! command -v shasum &> /dev/null; then
        error "sha256sum or shasum is required but neither is installed"
    fi
}

# Calculate SHA256 checksum (works on both Linux and macOS)
calculate_sha256() {
    local file="$1"
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        error "No sha256 tool available"
    fi
}

# Detect OS and architecture
detect_platform() {
    local os arch

    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Linux)
            case "$arch" in
                x86_64)
                    echo "linux-x86_64"
                    ;;
                aarch64|arm64)
                    echo "linux-arm64"
                    ;;
                *)
                    error "Unsupported Linux architecture: $arch. Only x86_64 and arm64 are supported."
                    ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                arm64)
                    echo "darwin-arm64"
                    ;;
                x86_64)
                    echo "darwin-x86_64"
                    ;;
                *)
                    error "Unsupported macOS architecture: $arch. Only arm64 and x86_64 are supported."
                    ;;
            esac
            ;;
        *)
            error "Unsupported operating system: $os"
            ;;
    esac
}

# Check if jq is available
HAS_JQ=false
check_jq() {
    if command -v jq >/dev/null 2>&1; then
        HAS_JQ=true
    fi
}

# Fallback JSON parser using bash regex (when jq is not available)
get_field_from_json_bash() {
    local json="$1"
    local platform="$2"
    local field="$3"

    # Normalize JSON to single line
    json=$(echo "$json" | tr -d '\n\r\t' | sed 's/ \+/ /g')

    # Extract value using bash regex
    if [[ "$field" == "size" ]]; then
        # For numeric fields
        if [[ $json =~ \"$platform\"[^}]*\"$field\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    else
        # For string fields
        if [[ $json =~ \"$platform\"[^}]*\"$field\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    fi

    return 1
}

# Get binary info from manifest for specific platform
get_binary_info() {
    local manifest_file="$1"
    local platform="$2"
    local field="$3"

    local manifest_content
    manifest_content=$(cat "$manifest_file")

    if [ "$HAS_JQ" = true ]; then
        local value
        value=$(echo "$manifest_content" | jq -r ".binaries[\"$platform\"][\"$field\"] // empty")
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi

    # Fallback to bash regex parser
    get_field_from_json_bash "$manifest_content" "$platform" "$field"
}

# Download manifest
download_manifest() {
    local manifest_url="$1"
    local tmp_manifest

    info "Downloading release manifest..."

    tmp_manifest=$(mktemp)
    TEMP_FILES+=("$tmp_manifest")

    if ! download_file "$manifest_url" "$tmp_manifest"; then
        error "Failed to download manifest from: $manifest_url"
    fi

    echo "$tmp_manifest"
}

# Add install directory to PATH in shell config
add_to_path() {
    local config_file="$1"
    local command="$2"

    if grep -Fxq "$command" "$config_file" 2>/dev/null; then
        info "PATH already configured in $config_file"
    elif [[ -w "$config_file" ]]; then
        echo -e "\n# ${BINARY_NAME}" >> "$config_file"
        echo "$command" >> "$config_file"
        info "${MUTED}Added ${NC}${BINARY_NAME}${MUTED} to \$PATH in ${NC}$config_file"
    else
        warn "Could not write to $config_file. Manually add:"
        echo "  $command"
    fi
}

# Configure PATH for the current shell
configure_path() {
    if [[ "$NO_MODIFY_PATH" == "true" ]]; then
        return
    fi

    # Check if already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        return
    fi

    local current_shell
    current_shell=$(basename "$SHELL")

    local config_files=""
    local XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

    case "$current_shell" in
        fish)
            config_files="$HOME/.config/fish/config.fish"
            ;;
        zsh)
            config_files="${ZDOTDIR:-$HOME}/.zshrc ${ZDOTDIR:-$HOME}/.zshenv $XDG_CONFIG_HOME/zsh/.zshrc"
            ;;
        bash)
            config_files="$HOME/.bashrc $HOME/.bash_profile $HOME/.profile $XDG_CONFIG_HOME/bash/.bashrc"
            ;;
        ash|sh)
            config_files="$HOME/.profile"
            ;;
        *)
            config_files="$HOME/.bashrc $HOME/.bash_profile $HOME/.profile"
            ;;
    esac

    # Find existing config file
    local config_file=""
    for file in $config_files; do
        if [[ -f "$file" ]]; then
            config_file="$file"
            break
        fi
    done

    if [[ -z "$config_file" ]]; then
        warn "No shell config file found for $current_shell."
        warn "Manually add to your PATH:"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
        return
    fi

    # Add PATH based on shell type
    case "$current_shell" in
        fish)
            add_to_path "$config_file" "fish_add_path $INSTALL_DIR"
            ;;
        *)
            add_to_path "$config_file" "export PATH=\"$INSTALL_DIR:\$PATH\""
            ;;
    esac

    # Handle GitHub Actions
    if [ -n "${GITHUB_ACTIONS:-}" ] && [ "${GITHUB_ACTIONS}" == "true" ]; then
        echo "$INSTALL_DIR" >> "$GITHUB_PATH"
        info "Added $INSTALL_DIR to \$GITHUB_PATH"
    fi
}

# Main installation function
install_binary() {
    local platform manifest_file binary_url expected_sha256 expected_size tmp_dir download_path

    # Check requirements
    check_requirements
    check_jq

    # Validate manifest URL
    if [ -z "$MANIFEST_URL" ]; then
        error "Manifest URL is required.\nUsage: $0 \"<manifest-url>\""
    fi

    info "Starting ${BINARY_NAME} installation..."

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Detect platform
    info "Detecting platform..."
    platform="$(detect_platform)"
    info "Platform detected: $platform"

    # Download manifest
    manifest_file="$(download_manifest "$MANIFEST_URL")"

    # Get binary info for this platform
    info "Parsing manifest for $platform binary..."
    binary_url="$(get_binary_info "$manifest_file" "$platform" "url")"
    expected_sha256="$(get_binary_info "$manifest_file" "$platform" "sha256")"
    expected_size="$(get_binary_info "$manifest_file" "$platform" "size")"

    if [ -z "$binary_url" ]; then
        error "Failed to get binary URL from manifest for platform: $platform"
    fi

    info "Binary URL found"
    [ -n "$expected_sha256" ] && info "Expected SHA256: $expected_sha256"
    [ -n "$expected_size" ] && info "Expected size: $expected_size bytes"

    # Create temporary directory for download
    tmp_dir="$(mktemp -d)"
    TEMP_DIRS+=("$tmp_dir")
    download_path="${tmp_dir}/${BINARY_NAME}.tar.gz"

    # Download binary tarball
    info "Downloading ${BINARY_NAME} binary..."
    if ! download_file "$binary_url" "$download_path"; then
        error "Failed to download binary from: $binary_url"
    fi

    # Verify file size
    if [ -n "$expected_size" ] && [ "$expected_size" != "null" ]; then
        info "Verifying file size..."
        actual_size=$(wc -c < "$download_path" | tr -d ' ')
        if [ "$actual_size" -ne "$expected_size" ]; then
            error "Size mismatch! Expected: $expected_size bytes, Got: $actual_size bytes"
        fi
        info "Size verification passed: $actual_size bytes"
    else
        warn "Size verification skipped (not specified in manifest)"
    fi

    # Verify SHA256 checksum
    if [ -n "$expected_sha256" ] && [ "$expected_sha256" != "null" ]; then
        info "Verifying SHA256 checksum..."
        actual_sha256=$(calculate_sha256 "$download_path")
        if [ "$actual_sha256" != "$expected_sha256" ]; then
            error "SHA256 mismatch! Expected: $expected_sha256, Got: $actual_sha256"
        fi
        info "SHA256 verification passed"
    else
        warn "SHA256 verification skipped (not specified in manifest)"
    fi

    # Extract tarball
    info "Extracting binary..."
    if ! tar -xzf "$download_path" -C "$tmp_dir"; then
        error "Failed to extract tarball"
    fi

    # Verify binary exists
    if [ ! -f "${tmp_dir}/${BINARY_NAME}" ]; then
        error "Binary '${BINARY_NAME}' not found in downloaded package"
    fi

    # Install binary (no sudo needed - we're in user's home directory)
    info "Installing ${BINARY_NAME} to ${INSTALL_DIR}..."
    cp "${tmp_dir}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod 755 "${INSTALL_DIR}/${BINARY_NAME}"

    info "${BINARY_NAME} installed successfully to ${INSTALL_DIR}/${BINARY_NAME}"

    # Configure PATH
    configure_path

    # Verify installation
    if command -v "$BINARY_NAME" &> /dev/null; then
        info "Verification: $($BINARY_NAME --version 2>/dev/null || echo "${BINARY_NAME} is available")"
    else
        echo ""
        warn "${BINARY_NAME} was installed but is not yet in your PATH."
        warn "To use it now, either:"
        echo ""
        echo "  1. Restart your shell, or"
        echo "  2. Run: source ~/.bashrc  (or ~/.zshrc for zsh)"
        echo "  3. Or run directly: ${INSTALL_DIR}/${BINARY_NAME}"
        echo ""
    fi
}

# Run installation
install_binary

echo ""
info "Installation complete!"
echo ""