#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

# Check if running on Ubuntu/Debian
check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID_LIKE" != *"ubuntu"* && "$ID_LIKE" != *"debian"* ]]; then
            print_warning "This script is designed for Ubuntu/Debian. Some packages may not install correctly."
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        fi
    fi
}

# Install apt packages
install_apt_packages() {
    print_header "Installing APT packages"
    
    sudo apt update
    sudo apt install -y \
        zsh \
        tmux \
        fzf \
        curl \
        wget \
        git \
        build-essential \
        stow \
        unzip \
        fontconfig
    
    print_success "APT packages installed"
}

# Install GitHub CLI
install_gh() {
    print_header "Installing GitHub CLI"
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    
    print_success "GitHub CLI installed"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    fi
    
    # Install zsh plugins
    print_step "Installing zsh-autosuggestions..."
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    
    print_step "Installing zsh-syntax-highlighting..."
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    
    # Install Powerlevel10k
    print_step "Installing Powerlevel10k..."
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi
    
    print_success "Zsh plugins installed"
}

# Install Rust and cargo tools
install_rust_tools() {
    print_header "Installing Rust and tools"
    
    if ! command -v cargo &> /dev/null; then
        print_step "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        print_success "Rust already installed"
    fi
    
    # Install tms (tmux-sessionizer)
    print_step "Installing tmux-sessionizer (tms)..."
    if ! command -v tms &> /dev/null; then
        cargo install tmux-sessionizer
    else
        print_success "tms already installed"
    fi
    
    print_success "Rust tools installed"
}

# Install gitmux
install_gitmux() {
    print_header "Installing gitmux"
    
    if command -v gitmux &> /dev/null; then
        print_success "gitmux already installed"
        return
    fi
    
    GITMUX_VERSION="0.10.3"
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) GITMUX_ARCH="amd64" ;;
        aarch64) GITMUX_ARCH="arm64" ;;
        *) print_error "Unsupported architecture: $ARCH"; return ;;
    esac
    
    curl -fsSL "https://github.com/arl/gitmux/releases/download/v${GITMUX_VERSION}/gitmux_v${GITMUX_VERSION}_linux_${GITMUX_ARCH}.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/gitmux /usr/local/bin/
    
    print_success "gitmux installed"
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    print_header "Installing TPM"
    
    TPM_DIR="$HOME/.config/tmux/plugins/tpm"
    
    if [ -d "$TPM_DIR" ]; then
        print_success "TPM already installed"
    else
        mkdir -p "$HOME/.config/tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        print_success "TPM installed"
    fi
    
    print_warning "After starting tmux, press prefix + I to install plugins"
}

# Install NVM
install_nvm() {
    print_header "Installing NVM"
    
    if [ -d "$HOME/.nvm" ]; then
        print_success "NVM already installed"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed"
    fi
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node
    print_step "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    
    print_success "Node.js LTS installed"
}

# Install Bun
install_bun() {
    print_header "Installing Bun"
    
    if command -v bun &> /dev/null; then
        print_success "Bun already installed"
    else
        curl -fsSL https://bun.sh/install | bash
        print_success "Bun installed"
    fi
}

# Install Turso CLI
install_turso() {
    print_header "Installing Turso CLI"
    
    if [ -f "$HOME/.turso/turso" ]; then
        print_success "Turso already installed"
    else
        curl -sSfL https://get.tur.so/install.sh | bash
        print_success "Turso installed"
    fi
}

# Install opencode
install_opencode() {
    print_header "Installing opencode"
    
    if command -v opencode &> /dev/null; then
        print_success "opencode already installed"
    else
        # Load bun if just installed
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        
        bun install -g opencode@latest
        print_success "opencode installed"
    fi
}

# Install Nerd Font (for Powerlevel10k icons)
install_nerd_font() {
    print_header "Installing Nerd Font"
    
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    if ls "$FONT_DIR"/*Iosevka*Nerd* &> /dev/null 2>&1; then
        print_success "Iosevka Nerd Font already installed"
        return
    fi
    
    print_step "Downloading Iosevka Nerd Font..."
    curl -fsSL -o /tmp/Iosevka.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip"
    unzip -o /tmp/Iosevka.zip -d "$FONT_DIR"
    rm /tmp/Iosevka.zip
    
    fc-cache -fv
    
    print_success "Iosevka Nerd Font installed"
}

# Stow dotfiles
stow_dotfiles() {
    print_header "Linking dotfiles with GNU Stow"
    
    cd "$DOTFILES_DIR"
    
    # Backup existing files
    backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Check for existing files and backup
    for package in zsh tmux git opencode ghostty ssh gh; do
        if [ -d "$package" ]; then
            print_step "Stowing $package..."
            
            # Try to stow, if fails due to existing files, backup and retry
            if ! stow -v --target="$HOME" "$package" 2>/dev/null; then
                print_warning "Backing up existing $package files..."
                mkdir -p "$backup_dir"
                stow -v --target="$HOME" --adopt "$package"
                git checkout -- "$package"
            fi
        fi
    done
    
    # Set correct permissions for SSH
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
    
    print_success "Dotfiles linked"
    [ -d "$backup_dir" ] && print_warning "Backups saved to: $backup_dir"
}

# Configure git user
configure_git() {
    print_header "Configuring Git"
    
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -z "$current_name" ]; then
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    else
        print_success "Git name already set: $current_name"
    fi
    
    if [ -z "$current_email" ]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    else
        print_success "Git email already set: $current_email"
    fi
    
    print_success "Git configured"
}

# Change default shell
change_shell() {
    print_header "Changing default shell to Zsh"
    
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_success "Zsh is already the default shell"
    else
        chsh -s "$(which zsh)"
        print_success "Default shell changed to Zsh"
        print_warning "Please log out and log back in for the change to take effect"
    fi
}

# Main installation
main() {
    print_header "Hugo's Dotfiles Installer"
    
    echo "This will install and configure:"
    echo "  • Zsh + Oh My Zsh + Powerlevel10k"
    echo "  • Tmux + TPM + tms"
    echo "  • Git + gitmux"
    echo "  • NVM + Bun"
    echo "  • Turso CLI"
    echo "  • opencode"
    echo "  • Ghostty config"
    echo "  • Iosevka Nerd Font"
    echo ""
    
    read -p "Continue? [Y/n] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
    
    check_distro
    install_apt_packages
    install_gh
    install_oh_my_zsh
    install_rust_tools
    install_gitmux
    install_tpm
    install_nvm
    install_bun
    install_turso
    install_opencode
    install_nerd_font
    stow_dotfiles
    configure_git
    change_shell
    
    print_header "Installation Complete!"
    
    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Log out and log back in (or run: exec zsh)"
    echo "  2. Start tmux and press prefix + I to install plugins"
    echo "  3. Run 'gh auth login' to authenticate with GitHub"
    echo "  4. Configure opencode with your API keys"
    echo ""
    echo -e "${YELLOW}Enjoy your new setup! 🚀${NC}"
}

# Run with optional arguments
case "${1:-}" in
    --minimal)
        check_distro
        install_apt_packages
        install_oh_my_zsh
        stow_dotfiles
        change_shell
        ;;
    --help|-h)
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (none)     Full installation"
        echo "  --minimal  Only zsh, tmux and dotfiles"
        echo "  --help     Show this help"
        ;;
    *)
        main
        ;;
esac
