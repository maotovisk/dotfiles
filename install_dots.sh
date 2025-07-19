#!/bin/sh

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE=true
fi

print_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $1"
}

print_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

symlink() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$FORCE" = true ]; then
            rm -rf "$dest"
            print_warn "Removed existing $dest"
        else
            print_warn "$dest already exists, skipping..."
            return
        fi
    fi

    ln -sf "$src" "$dest"
    print_info "Symlink created for $dest"
}

DOTFILES_DIR=$(pwd)

function install_config_files() {
    print_info "Installing config files from $DOTFILES_DIR/config"

    # Symlink config folders
    CONFIGS=(fish hypr mako waybar wofi)
    for config in "${CONFIGS[@]}"; do
        symlink "$DOTFILES_DIR/config/$config" "$HOME/.config/$config"
    done
}

function install_sul_uploader() {
    print_info "Installing sul-uploader"

    # Symlink sul-uploader executable
    mkdir -p "$HOME/.local/bin"
    symlink "$DOTFILES_DIR/local/bin/sul-uploader" "$HOME/.local/bin/sul-uploader"
    chmod +x "$HOME/.local/bin/sul-uploader"

    # Handle sul-uploader config separately
    SUL_UPLOADER_DIR="$HOME/.config/sul-uploader"
    mkdir -p "$SUL_UPLOADER_DIR"
    CONFIG_INI="$SUL_UPLOADER_DIR/config.ini"

    if [ -f "$CONFIG_INI" ] && [ "$FORCE" = false ]; then
        print_warn "$CONFIG_INI already exists, skipping creation..."
    else
        print_info "Creating $CONFIG_INI"
        pritn_info "Get your key from https://s-ul.eu/account/preferences and paste it below."
        read -p "Enter the key for sul-uploader: " SUL_KEY
        echo -e "[DEFAULT]\nkey=$SUL_KEY" > "$CONFIG_INI"
        print_info "Created $CONFIG_INI"
    fi
}

function install_wallpapers() {
    print_info "Installing wallpapers"

    # Symlink wallpapers
    WALLPAPER_DIR="$HOME/.wallpapers"
    mkdir -p "$WALLPAPER_DIR"
    symlink "$DOTFILES_DIR/wallpapers/wpp3.jpg" "$WALLPAPER_DIR/wpp3.jpg"
}

function install_dotfiles() {
    install_config_files
    install_sul_uploader
    install_wallpapers

    print_info "Dotfiles installation complete!"
}


# Usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [--force | -f]"
    echo "Install dotfiles and configurations."
    echo "Options:"
    echo "  --force, -f   Force overwrite existing files"
    exit 0
fi

# Start installation
print_info "Starting dotfiles installation..."
install_dotfiles
