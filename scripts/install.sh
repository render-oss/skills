#!/bin/bash
set -eo pipefail

# Temp files to clean up on exit
TOOLS_FILE=""
TEMP_DIR=""

cleanup() {
    [ -n "$TOOLS_FILE" ] && rm -f "$TOOLS_FILE" 2>/dev/null
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR" 2>/dev/null
}
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository information
REPO_URL="git@github.com:render-oss/skills.git"
HTTPS_REPO_URL="https://github.com/render-oss/skills.git"
PLUGIN_NAME="render"

# Print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check authentication status - returns "method" or empty string
check_auth() {
    if [ -n "$RENDER_API_KEY" ]; then
        echo "API key (RENDER_API_KEY)"
    elif command -v render &> /dev/null && render whoami -o json &> /dev/null; then
        echo "Render CLI (render whoami)"
    fi
}

# Detect shell config file
detect_shell_config() {
    for config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
        if [ -f "$config" ]; then
            echo "$config"
            return
        fi
    done
}

# Prompt user to set up authentication
setup_auth() {
    echo ""
    print_warning "Authentication not configured"
    echo ""
    print_info "Render skills require authentication."
    print_info "Choose one of these options:"
    echo ""
    echo -e "  ${BLUE}Option 1: API Key (Recommended)${NC}"
    echo "    1. Get your API key: https://dashboard.render.com/u/*/settings#api-keys"
    echo "    2. Add to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "       export RENDER_API_KEY=\"rnd_your_key_here\""
    echo "    3. Restart your terminal or run: source ~/.zshrc"
    echo ""
    echo -e "  ${BLUE}Option 2: Render CLI Login${NC}"
    echo "    1. Login: render login"
    echo ""

    read -rp "Would you like to set up authentication now? [y/N] " -n 1 REPLY
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi

    echo ""
    echo "Choose authentication method:"
    echo "  1) API Key (Recommended)"
    echo "  2) Render CLI Login"
    echo ""
    read -rp "Enter choice [1/2]: " -n 1 auth_choice
    echo ""

    if [ "$auth_choice" = "2" ]; then
        print_info "Logging in via Render CLI..."
        if render login; then
            print_success "Logged in successfully"
            return 0
        else
            print_error "Login failed"
            return 1
        fi
    fi

    echo ""
    read -rp "Enter your Render API key (or press Enter to skip): " api_key

    if [ -z "$api_key" ]; then
        return 1
    fi

    local shell_config
    shell_config=$(detect_shell_config)

    if [ -z "$shell_config" ]; then
        print_warning "Could not detect shell config file"
        print_info "Add this to your shell profile manually:"
        echo "    export RENDER_API_KEY=\"$api_key\""
        export RENDER_API_KEY="$api_key"
        return 0
    fi

    if grep -q "RENDER_API_KEY" "$shell_config" 2>/dev/null; then
        print_warning "RENDER_API_KEY already exists in $shell_config"
        print_info "Please update it manually if needed"
    else
        {
            echo ""
            echo "# Render API Key"
            echo "export RENDER_API_KEY=\"$api_key\""
        } >> "$shell_config"
        print_success "API key added to $shell_config"
        print_info "Run: source $shell_config"
    fi

    export RENDER_API_KEY="$api_key"
}

# Detect available tools and their skills directories
detect_tools() {
    local tools_file=$(mktemp)

    # Check for Claude Code (global)
    if [ -d "$HOME/.claude" ]; then
        # Claude Code may not create ~/.claude/skills until the first custom skill is added
        if [ ! -d "$HOME/.claude/skills" ]; then
            mkdir -p "$HOME/.claude/skills" 2>/dev/null || true
        fi
        if [ -d "$HOME/.claude/skills" ]; then
            echo "$HOME/.claude/skills" >> "$tools_file"
        fi
    fi

    # Check for Claude Code (local - current directory)
    if [ -d "./.claude" ]; then
        if [ ! -d "./.claude/skills" ]; then
            mkdir -p "./.claude/skills" 2>/dev/null || true
        fi
        if [ -d "./.claude/skills" ]; then
            echo "./.claude/skills" >> "$tools_file"
        fi
    fi

    # Check for Codex
    if [ -d "$HOME/.codex" ]; then
        if [ ! -d "$HOME/.codex/skills" ]; then
            mkdir -p "$HOME/.codex/skills" 2>/dev/null || true
        fi
        if [ -d "$HOME/.codex/skills" ]; then
            echo "$HOME/.codex/skills" >> "$tools_file"
        fi
    fi

    # Check for OpenCode
    if [ -d "$HOME/.config/opencode" ]; then
        if [ ! -d "$HOME/.config/opencode/skills" ]; then
            mkdir -p "$HOME/.config/opencode/skills" 2>/dev/null || true
        fi
        if [ -d "$HOME/.config/opencode/skills" ]; then
            echo "$HOME/.config/opencode/skills" >> "$tools_file"
        fi
    fi

    # Check for Cursor
    if [ -d "$HOME/.cursor" ]; then
        # Cursor may not create ~/.cursor/skills until the first custom skill is added.
        if [ ! -d "$HOME/.cursor/skills" ]; then
            mkdir -p "$HOME/.cursor/skills" 2>/dev/null || true
        fi
        if [ -d "$HOME/.cursor/skills" ]; then
            echo "$HOME/.cursor/skills" >> "$tools_file"
        fi
    fi

    echo "$tools_file"
}

# Check and install Render CLI
install_render_cli() {
    # Check if render CLI is already installed
    if command -v render &> /dev/null; then
        local version=$(render --version 2>&1 | head -n1)
        print_success "Render CLI already installed: $version"
        return 0
    fi

    print_info "Render CLI not found. Installing..."
    echo ""

    # Detect OS
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [ "$os" = "darwin" ]; then
        # macOS - try Homebrew first
        if command -v brew &> /dev/null; then
            print_info "Installing via Homebrew..."
            if brew install render 2>/dev/null; then
                print_success "Render CLI installed via Homebrew"
                return 0
            fi
        fi
    fi

    # Fallback to curl install script for all platforms
    print_info "Installing via official install script..."
    if curl -fsSL https://raw.githubusercontent.com/render-oss/cli/main/bin/install.sh | sh; then
        print_success "Render CLI installed successfully"
        return 0
    else
        print_warning "Failed to install Render CLI automatically"
        print_info "Manual installation: https://render.com/docs/cli"
        return 1
    fi
}

# Clone repository
setup_repo() {
    local temp_dir=$(mktemp -d)

    if GIT_SSH_COMMAND="ssh -o BatchMode=yes" git clone --quiet --depth 1 "$REPO_URL" "$temp_dir" 2>/dev/null; then
        echo "$temp_dir"
        return 0
    fi

    if git clone --quiet --depth 1 "$HTTPS_REPO_URL" "$temp_dir" 2>/dev/null; then
        echo "$temp_dir"
        return 0
    else
        echo ""
        return 1
    fi
}

# Install skills to a specific tool directory
install_to_tool() {
    local tool_dir=$1
    local source_dir=$2

    # Create skills directory if it doesn't exist
    mkdir -p "$tool_dir"

    # Remove old installations if they exist
    rm -rf "${tool_dir}/${PLUGIN_NAME}"-* 2>/dev/null || true

    # Remove old nested plugin structure if it exists
    rm -rf "$tool_dir/${PLUGIN_NAME}" 2>/dev/null || true

    # Track installed skill count
    local skill_count=0

    # Copy each skill as a top-level directory
    if [ -d "$source_dir/skills" ]; then
        for skill_dir in "$source_dir"/skills/*/; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")

                # Skip hidden or special directories
                [[ "$skill_name" == _* ]] && continue

                # Check if this is a valid skill (has SKILL.md)
                if [ -f "$skill_dir/SKILL.md" ]; then
                    # Copy skill directly to tool_dir
                    cp -r "$skill_dir" "$tool_dir/${skill_name}"
                    ((++skill_count))
                fi
            fi
        done
    fi

    # Return success if at least one skill was installed
    [ $skill_count -gt 0 ] && return 0 || return 1
}

# Main installation flow
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║          Render Skill Installer          ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"

    # Detect available tools
    print_info "Detecting installed AI coding tools..."
    echo ""

    local cursor_skills_missing=false
    if [ -d "$HOME/.cursor" ] && [ ! -d "$HOME/.cursor/skills" ]; then
        cursor_skills_missing=true
    fi

    TOOLS_FILE=$(detect_tools)
    local tools=()

    # Read detected tools and display them
    while IFS= read -r tool_dir; do
        if [ -n "$tool_dir" ]; then
            tools+=("$tool_dir")

            # Print user-friendly location
            case "$tool_dir" in
                "$HOME/.claude/skills")
                    print_info "Found Claude Code (global): ~/.claude"
                    ;;
                "./.claude/skills")
                    print_info "Found Claude Code (local): ./.claude"
                    ;;
                "$HOME/.codex/skills")
                    print_info "Found Codex: ~/.codex"
                    ;;
                "$HOME/.config/opencode/skills")
                    print_info "Found OpenCode: ~/.config/opencode"
                    ;;
                "$HOME/.cursor/skills")
                    print_info "Found Cursor: ~/.cursor"
                    ;;
            esac
        fi
    done < "$TOOLS_FILE"

    if [ "$cursor_skills_missing" = true ]; then
        if [ -d "$HOME/.cursor/skills" ]; then
            print_info "Created ~/.cursor/skills for Cursor"
        else
            print_warning "Cursor detected at ~/.cursor, but ~/.cursor/skills could not be created"
        fi
    fi

    rm -f "$TOOLS_FILE"
    TOOLS_FILE=""

    if [ ${#tools[@]} -eq 0 ]; then
        echo ""
        print_error "No supported tools detected"
        print_info "Supported tools: Claude Code, Codex, OpenCode, Cursor"
        print_info "Please install one of these tools or create a .claude directory"
        exit 1
    fi

    echo ""
    print_success "Detected ${#tools[@]} tool installation(s)"
    echo ""

    # Install Render CLI
    install_render_cli
    echo ""

    # Setup repository
    print_info "Cloning Render skills repository..."
    TEMP_DIR=$(setup_repo)

    if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
        print_error "Failed to clone repository"
        exit 1
    fi

    print_success "Repository cloned successfully"
    echo ""

    # Install to each detected tool
    local install_count=0
    for tool_dir in "${tools[@]}"; do
        print_info "Installing to: $tool_dir"

        if install_to_tool "$tool_dir" "$TEMP_DIR"; then
            # Count installed skills
            local skill_count=$(find "$tool_dir" -maxdepth 1 -name "${PLUGIN_NAME}-*" -type d 2>/dev/null | wc -l)
            print_success "Installed ${skill_count} skill(s)"

            ((++install_count))
        else
            print_error "Installation failed"
        fi
        echo ""
    done

    # Cleanup
    print_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    TEMP_DIR=""

    # Final message
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║          Installation Complete!          ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    if [ $install_count -eq 0 ]; then
        print_error "Skills installation failed"
        exit 1
    elif [ $install_count -eq 1 ]; then
        print_success "Skills installed to 1 tool"
    else
        print_success "Skills installed to $install_count tools"
    fi

    # Check authentication
    print_info "Checking authentication..."
    local auth_method
    auth_method=$(check_auth)

    if [ -z "$auth_method" ]; then
        setup_auth
        auth_method=$(check_auth)
    else
        print_success "Authenticated via $auth_method"
    fi

    echo ""
    print_info "Available skills:"
    echo "  • /render-deploy - Deployment and service management"
    echo "  • /render-debug - Debugging and troubleshooting"
    echo "  • /render-monitor - Monitoring and health checks"
    echo ""

    if [ -n "$auth_method" ]; then
        print_success "Authentication configured ($auth_method)"
    else
        print_warning "Authentication not configured - skills will have limited functionality"
        print_info "Set up later: https://dashboard.render.com/u/*/settings#api-keys"
    fi

    echo ""
    print_warning "Restart your AI tool to load the skills"
    echo ""
}

# Run main function
main
