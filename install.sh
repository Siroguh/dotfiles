#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNATTENDED=false

print_header() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${BLUE}  $1${NC}\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
print_step() { echo -e "${GREEN}▶${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✖${NC} $1"; }
print_success() { echo -e "${GREEN}✔${NC} $1"; }

install_apt_packages() {
    print_header "Installing APT packages"
    sudo apt update
    sudo apt install -y zsh tmux fzf curl wget git build-essential stow unzip fontconfig
    print_success "APT packages installed"
}

install_gh() {
    print_header "Installing GitHub CLI"
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    print_success "GitHub CLI installed"
}

install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    fi
    
    print_step "Installing zsh-autosuggestions..."
    [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    
    print_step "Installing zsh-syntax-highlighting..."
    [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    
    print_step "Installing Powerlevel10k..."
    [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] && \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    print_success "Zsh plugins installed"
}

install_rust_tools() {
    print_header "Installing Rust and cargo tools"
    if ! command -v cargo &> /dev/null; then
        print_step "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        print_success "Rust already installed"
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi
    
    print_step "Installing tms, delta, bat, eza..."
    command -v tms &> /dev/null || cargo install tmux-sessionizer
    command -v delta &> /dev/null || cargo install git-delta
    command -v bat &> /dev/null || cargo install bat
    command -v eza &> /dev/null || cargo install eza
    print_success "Rust tools installed"
}

install_atuin() {
    print_header "Installing Atuin"
    if command -v atuin &> /dev/null; then
        print_success "Atuin already installed"
        return
    fi
    curl -fsSL https://setup.atuin.sh | bash
    print_success "Atuin installed"
}

install_lazygit() {
    print_header "Installing Lazygit"
    if command -v lazygit &> /dev/null; then
        print_success "Lazygit already installed"
        return
    fi
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit.tar.gz /tmp/lazygit
    print_success "Lazygit installed"
}

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
}

install_nvm() {
    print_header "Installing NVM"
    if [ -d "$HOME/.nvm" ]; then
        print_success "NVM already installed"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed"
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    print_step "Installing Node.js LTS..."
    nvm install --lts
    print_success "Node.js LTS installed"
}

install_bun() {
    print_header "Installing Bun"
    if command -v bun &> /dev/null; then
        print_success "Bun already installed"
    else
        curl -fsSL https://bun.sh/install | bash
        print_success "Bun installed"
    fi
}

install_turso() {
    print_header "Installing Turso CLI"
    if [ -f "$HOME/.turso/turso" ]; then
        print_success "Turso already installed"
    else
        curl -sSfL https://get.tur.so/install.sh | bash
        print_success "Turso installed"
    fi
}

install_opencode() {
    print_header "Installing opencode"
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    if command -v opencode &> /dev/null; then
        print_success "opencode already installed"
    else
        bun install -g opencode@latest
        print_success "opencode installed"
    fi
}

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

stow_dotfiles() {
    print_header "Linking dotfiles with GNU Stow"
    cd "$DOTFILES_DIR"
    for package in zsh tmux git opencode ghostty ssh gh lazygit atuin bat; do
        if [ -d "$package" ]; then
            print_step "Stowing $package..."
            stow -v --target="$HOME" --adopt "$package" 2>/dev/null || true
            git checkout -- "$package" 2>/dev/null || true
        fi
    done
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
    print_success "Dotfiles linked"
}

configure_git() {
    print_header "Configuring Git"
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$current_name" ]; then
        print_success "Git name: $current_name"
    elif [ "$UNATTENDED" = false ]; then
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    else
        print_warning "Git name not set (run: git config --global user.name 'Your Name')"
    fi
    
    if [ -n "$current_email" ]; then
        print_success "Git email: $current_email"
    elif [ "$UNATTENDED" = false ]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    else
        print_warning "Git email not set (run: git config --global user.email 'you@email.com')"
    fi
}

change_shell() {
    print_header "Changing default shell to Zsh"
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_success "Zsh is already the default shell"
    else
        chsh -s "$(which zsh)"
        print_success "Default shell changed to Zsh"
    fi
}

main() {
    print_header "Hugo's Dotfiles Installer"
    echo "This will install: Zsh, Oh My Zsh, Powerlevel10k, Tmux, TPM, tms, Git, gitmux, delta, lazygit, atuin, eza, bat, NVM, Bun, Turso, opencode, Iosevka Nerd Font"
    echo ""
    
    if [ "$UNATTENDED" = false ]; then
        read -p "Continue? [Y/n] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && exit 0
    fi
    
    install_apt_packages
    install_gh
    install_oh_my_zsh
    install_rust_tools
    install_atuin
    install_lazygit
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
    echo "  1. Log out and back in (or: exec zsh)"
    echo "  2. In tmux, press Ctrl+a I to install plugins"
    echo "  3. Run 'gh auth login'"
}

case "${1:-}" in
    -y|--yes|--unattended)
        UNATTENDED=true
        main
        ;;
    --minimal)
        install_apt_packages
        install_oh_my_zsh
        stow_dotfiles
        change_shell
        ;;
    --help|-h)
        echo "Usage: $0 [option]"
        echo "  (none)       Interactive install"
        echo "  -y, --yes    Unattended install (no prompts)"
        echo "  --minimal    Only zsh, tmux, stow"
        ;;
    *)
        main
        ;;
esac
