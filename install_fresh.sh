#!/bin/sh

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

print_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $1"
}

print_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

DO_COMPLETE_INSTALL=false
if [ "$1" = "--complete" ] || [ "$1" = "-c" ]; then
    DO_COMPLETE_INSTALL=true
fi

check_os() {
    ## if arch linux
    if [ -f /etc/arch-release ]; then
        print_info "Detected Arch Linux"
        return 0
    else
        print_error "This script is only for Arch Linux."
        exit 1
    fi
}

## helper to install packages, supports multiple packages (using pacman)
install_package() {
    local packages="$1"
    if [ -z "$packages" ]; then
        print_error "No packages specified for installation."
        return 1
    fi

    print_info "Installing packages: $packages"
    sudo pacman -S --noconfirm $packages
    if [ $? -ne 0 ]; then
        print_error "Failed to install packages: $packages"
        return 1
    fi

    print_info "Packages installed successfully."
}

DEPENDENCIES="git base-devel fish curl jq wl-clipboard"

HYPRLAND_PACKAGES="hyprland aquamarine xdg-desktop-portal-hyprland hyprpaper hyprland-qtutils hyprlang hyprland-qt-support hyprcursor hyprutils hyprgraphics"

EXTRA_PACKAGES="waybar wofi mako"

install_yay() {
    print_info "Installing yay (Yet Another Yaourt)..."
    if ! command -v yay &> /dev/null; then
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit 1
        makepkg -si --noconfirm
        cd .. && rm -rf yay
        print_info "yay installed successfully."
    else
        print_warn "yay is already installed."
    fi
}

change_shell() {
    if [ "$SHELL" != "$(which fish)" ]; then
        print_info "Changing default shell to fish..."
        chsh -s "$(which fish)"
        if [ $? -eq 0 ]; then
            print_info "Default shell changed to fish successfully."
        else
            print_error "Failed to change default shell."
        fi
    else
        print_warn "Fish is already the default shell."
    fi
}

install_extras() {
    print_info "Installing docker and related tools..."
    install_package "docker docker-compose docker-buildx"
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    print_info "Installing Zed Editor..."
    install_package "zed"

    print_info "Visual Studio Code (bin)..."
    yay -S --noconfirm visual-studio-code-bin

    print_info "Installing discord..."
    yay -S --noconfirm discord

    print_info "Installing Noto and CJK fonts..."
    install_package "noto-fonts-cjk noto-fonts-emoji noto-fonts-extra"

    print_info "Installing additional fonts..."
    install_package "inter-font ttf-jetbrains-mono ttf-fira-code ttf-roboto ttf-ubuntu-font-family"

    print_info "Installing Nerd Fonts..."
    yay -S --noconfirm nerd-fonts

    print_info "Installing additional utilities..."
    install_package "fastfetch htop btop bat zoxide"

    print_info "Installing osu..."
    yay -S --noconfirm osu-lazer-tachyon-bin

    print_info "Installing steam..."
    yay -S --noconfirm steam

    print_info "Installing GPU Screen Recorder..."
    yay -S --noconfirm gpu-screen-recorder gpu-screen-recorder-gtk gpu-screen-recorder-ui

    print_info "Installing vesktop..."
    yay -S --noconfirm vesktop
}

install_config_files() {
    #run install_dots.sh script to symlink config files
    print_info "Installing config files..."
    if [ -f "$PWD/install_dots.sh" ]; then
        bash "$PWD/install_dots.sh"
    else
        print_error "install_dots.sh not found in $PWD/"
        exit 1
    fi
    print_info "Config files installed successfully."
}

install_deps() {
    check_os

    print_info "Installing base dependencies..."
    install_package "$DEPENDENCIES"

    print_info "Installing Hyprland packages..."
    install_package "$HYPRLAND_PACKAGES"

    print_info "Installing extra packages..."
    install_package "$EXTRA_PACKAGES"

    print_info "Installing yay (AUR helper)..."
    install_yay

    print_info "Installing grimblast..."
    yay -S --noconfirm grimblast-git

    if [ "$DO_COMPLETE_INSTALL" = true ]; then
        install_extras
    fi

    print_info "Changing shell to fish..."
    change_shell

    print_info "All dependencies installed successfully."

    print_info "Do you want to install config files? (Y/n)"
    read -r install_configs
    if [ "$install_configs" = "Y" ] || [ "$install_configs" = "y" ]; then
        print_info "Installing config files..."
        install_config_files
    else
        print_warn "Skipping config files installation."
    fi
}
