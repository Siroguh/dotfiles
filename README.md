# Hugo's Dotfiles

My personal configuration files for Ubuntu/Debian systems.

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## What's Included

| Package | Description |
|---------|-------------|
| **zsh** | Shell config with Oh My Zsh + Powerlevel10k |
| **tmux** | Terminal multiplexer with TPM, tms, and custom sessionizer |
| **git** | Git config with gitmux integration for tmux status |
| **opencode** | AI coding assistant configuration |
| **ghostty** | Terminal emulator config |
| **ssh** | SSH client configuration |

## Installed Tools

The install script will set up:

- **Zsh** + Oh My Zsh + Powerlevel10k theme
- **Zsh plugins**: autosuggestions, syntax-highlighting, z, sudo
- **Tmux** + TPM (plugin manager) + tms (sessionizer)
- **Git** + gitmux (git status in tmux)
- **NVM** + Node.js LTS
- **Bun** runtime
- **Turso** CLI
- **opencode** AI assistant
- **GitHub CLI** (gh)
- **Iosevka Nerd Font**

## Manual Steps After Install

1. Log out and back in (or `exec zsh`)
2. Start tmux and press `Ctrl+a I` to install plugins
3. Run `gh auth login` to authenticate with GitHub
4. Configure opencode API keys

## Key Bindings

### Tmux (prefix: Ctrl+a)

| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontally |
| `prefix + -` | Split vertically |
| `prefix + s` | Custom session picker (fzf) |
| `prefix + Ctrl+o` | tms session picker |
| `prefix + Ctrl+s` | tms switch session |
| `prefix + Ctrl+w` | tms switch window |
| `prefix + Ctrl+k` | Kill current session |
| `prefix + r` | Reload config |

### Zsh

Uses Oh My Zsh with these plugins:
- `git` - Git aliases
- `docker` - Docker completions
- `z` - Jump to directories
- `sudo` - Press ESC twice to add sudo

## Structure

```
dotfiles/
├── install.sh          # Main installer
├── git/
│   ├── .gitconfig
│   ├── .gitmux.conf
│   └── .config/git/ignore
├── zsh/
│   ├── .zshrc
│   ├── .zshenv
│   └── .p10k.zsh
├── tmux/
│   └── .config/tmux/
│       ├── tmux.conf
│       └── scripts/sessionizer.sh
├── opencode/
│   └── .config/opencode/
│       ├── opencode.json
│       └── oh-my-opencode.json
├── ghostty/
│   └── .config/ghostty/config
└── ssh/
    └── .ssh/config
```

## Minimal Install

For a quick setup with just zsh and dotfiles:

```bash
./install.sh --minimal
```

## Requirements

- Ubuntu/Debian-based system
- `sudo` access
- Internet connection

## License

MIT
