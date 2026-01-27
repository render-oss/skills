#!/bin/bash
set -e

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

# Detect available tools and their skills directories
detect_tools() {
    local tools_file=$(mktemp)

    # Check for Claude Code (global)
    if [ -d "$HOME/.claude" ]; then
        echo "$HOME/.claude/skills" >> "$tools_file"
    fi

    # Check for Claude Code (local - current directory)
    if [ -d "./.claude" ]; then
        echo "./.claude/skills" >> "$tools_file"
    fi

    # Check for Codex
    if [ -d "$HOME/.codex/skills" ]; then
        echo "$HOME/.codex/skills" >> "$tools_file"
    fi

    # Check for OpenCode
    if [ -d "$HOME/.config/opencode/skills" ]; then
        echo "$HOME/.config/opencode/skills" >> "$tools_file"
    fi

    # Check for Cursor
    if [ -d "$HOME/.cursor/skills" ]; then
        echo "$HOME/.cursor/skills" >> "$tools_file"
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

# Install plugin to a specific tool directory
install_to_tool() {
    local tool_dir=$1
    local source_dir=$2

    # Create skills directory if it doesn't exist
    mkdir -p "$tool_dir"

    # Remove old installations if they exist
    rm -rf "$tool_dir"/${PLUGIN_NAME}-* 2>/dev/null || true

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
                    ((skill_count++))
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
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          Render Plugin Installer                      ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Detect available tools
    print_info "Detecting installed AI coding tools..."
    echo ""

    local tools_file=$(detect_tools)
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
                "$HOME/.config/codex/skills")
                    print_info "Found Codex: ~/.config/codex"
                    ;;
                "$HOME/.config/opencode/skills")
                    print_info "Found OpenCode: ~/.config/opencode"
                    ;;
                "$HOME/.cursor/skills")
                    print_info "Found Cursor: ~/.cursor"
                    ;;
            esac
        fi
    done < "$tools_file"

    rm -f "$tools_file"

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
    print_info "Cloning Render plugin repository..."
    print_info "Repository access required (private repo)"
    temp_dir=$(setup_repo)

    if [ -z "$temp_dir" ] || [ ! -d "$temp_dir" ]; then
        print_error "Failed to clone repository"
        exit 1
    fi

    print_success "Repository cloned successfully"
    echo ""

    # Install to each detected tool
    local install_count=0
    for tool_dir in "${tools[@]}"; do
        print_info "Installing to: $tool_dir"

        if install_to_tool "$tool_dir" "$temp_dir"; then
            # Count installed skills
            local skill_count=$(find "$tool_dir" -maxdepth 1 -name "${PLUGIN_NAME}-*" -type d 2>/dev/null | wc -l)
            print_success "Installed ${skill_count} skill(s)"

            ((install_count++))
        else
            print_error "Installation failed"
        fi
        echo ""
    done

    # Cleanup
    print_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"

    # Final message
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          Installation Complete!                       ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    if [ $install_count -eq 0 ]; then
        print_error "Plugin installation failed"
        exit 1
    elif [ $install_count -eq 1 ]; then
        print_success "Plugin installed to 1 tool"
    else
        print_success "Plugin installed to $install_count tools"
    fi

    echo ""
    print_info "Available skills:"
    echo "  • /render-deploy - Deployment and service management"
    echo "  • /render-debug - Debugging and troubleshooting"
    echo "  • /render-monitor - Monitoring and health checks"
    echo ""
    print_warning "Restart your AI tool to load the skills"
    echo ""
    print_info "Authenticate with Render (choose one):"
    echo "  • API Key: export RENDER_API_KEY=\"your_key_here\""
    echo "    Get your key: https://dashboard.render.com/settings/api-keys"
    echo "  • CLI Login: render login"
    echo ""
}

# Run main function
main
