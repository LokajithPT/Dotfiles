#!/bin/bash

# =============================================================================
# Dotfiles Installation Script
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Create backup of existing files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r "$file" "$backup_dir/"
        log "Backed up $file to $backup_dir"
    fi
}

# Create symbolic link
create_link() {
    local source="$1"
    local target="$2"
    local target_dir=$(dirname "$target")
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Backup existing file
    backup_file "$target"
    
    # Create symbolic link
    ln -sf "$source" "$target"
    success "Linked $source -> $target"
}

# Install dotfiles
install_dotfiles() {
    log "Installing dotfiles..."
    
    local dotfiles_dir="$HOME/dotfiles"
    
    # Check if dotfiles directory exists
    if [[ ! -d "$dotfiles_dir" ]]; then
        error "Dotfiles directory not found at $dotfiles_dir"
        exit 1
    fi
    
    # Home directory files
    create_link "$dotfiles_dir/.gitconfig" "$HOME/.gitconfig"
    create_link "$dotfiles_dir/.tmux.conf" "$HOME/.tmux.conf"
    create_link "$dotfiles_dir/.p10k.zsh" "$HOME/.p10k.zsh"
    create_link "$dotfiles_dir/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
    
    # ZSH
    create_link "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
    
    # .config directory items
    create_link "$dotfiles_dir/hyde/.config/hyde" "$HOME/.config/hyde"
    create_link "$dotfiles_dir/hypr/.config/hypr" "$HOME/.config/hypr"
    create_link "$dotfiles_dir/kitty/.config/kitty" "$HOME/.config/kitty"
    create_link "$dotfiles_dir/nvim/.config/nvim" "$HOME/.config/nvim"
    create_link "$dotfiles_dir/rofi/.config/rofi" "$HOME/.config/rofi"
    create_link "$dotfiles_dir/waybar/.config/waybar" "$HOME/.config/waybar"
    create_link "$dotfiles_dir/swaylock/.config/swaylock" "$HOME/.config/swaylock"
    create_link "$dotfiles_dir/wlogout/.config/wlogout" "$HOME/.config/wlogout"
    
    # Scripts
    create_link "$dotfiles_dir/scripts" "$HOME/.local/bin/scripts"
    
    # Add scripts to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        log "Added scripts directory to PATH"
    fi
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    # Check if package manager is available
    if command -v pacman &> /dev/null; then
        log "Detected Arch Linux/Manjaro"
        # Add packages you want to install here
        # sudo pacman -S --needed git zsh hyprland kitty waybar rofi swaylock wlogout neovim tmux
    elif command -v apt &> /dev/null; then
        log "Detected Debian/Ubuntu"
        # Add packages you want to install here
        # sudo apt update && sudo apt install -y git zsh hyprland kitty waybar rofi swaylock wlogout neovim tmux
    elif command -v dnf &> /dev/null; then
        log "Detected Fedora"
        # Add packages you want to install here
        # sudo dnf install -y git zsh hyprland kitty waybar rofi swaylock wlogout neovim tmux
    else
        warning "Unsupported package manager. Please install dependencies manually."
    fi
}

# Set shell to ZSH
set_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        log "Changing default shell to ZSH..."
        chsh -s "$(which zsh)" || warning "Failed to change shell. Please run 'chsh -s \$(which zsh)' manually"
    else
        success "ZSH is already the default shell"
    fi
}

# Install vim-plug for neovim
install_vimplug() {
    log "Installing vim-plug for Neovim..."
    
    if [[ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]]; then
        sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        success "vim-plug installed"
    else
        success "vim-plug already installed"
    fi
}

# Main installation function
main() {
    log "Starting dotfiles installation..."
    
    check_root
    
    # Create directories
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.dotfiles_backup"
    
    # Install everything
    install_dependencies
    install_dotfiles
    install_vimplug
    set_shell
    
    log "Installation complete!"
    log "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    log "Run :PlugInstall in Neovim to install plugins"
    
    success "Dotfiles installed successfully! 🎉"
}

# Handle interrupt signal
trap 'error "Installation interrupted"; exit 1' INT

# Run main function
main "$@"