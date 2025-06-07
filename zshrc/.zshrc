# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

export ZSH="$HOME/.oh-my-zsh"
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure

# ZSH_THEME="robbyrussell"
# ZSH_THEME="pure"
# ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions docker zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$HOME/development/flutter/bin:$PATH"
export PATH="~/development/android-studio/bin/:$PATH"
export PATH="$PATH:/home/rb/go/bin"
export PATH="$PATH:~/.config/emacs/bin"
export ANDROID_HOME="/home/rb003/Android/Sdk/"

. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias cat="bat"
alias cd="z"
alias ls="eza --icons=always -la"
alias cprun="~/scripts/cp-run"
alias wifi_run="~/scripts/wifi_run"
alias tmux-sessionizer="~/scripts/tmux-sessionizer"
alias c="clear"
alias vi="nvim"
alias nvim2="NVIM_APPNAME=nvim2 nvim"
alias wifi="nmcli d wifi"
alias axel="axel -n 10"

eval "$(zoxide init zsh)"

bindkey -s ^f "sh ~/scripts/tmux-sessionizer\n"
export CPLUS_INCLUDE_PATH="$HOME/atcoder-library:$CPLUS_INCLUDE_PATH"
alias fullexpand="python3 $HOME/atcoder-library/expander.py"
# setxkbmap -option caps:escape &

if [ -z "$TMUX" ]; then
  tmux
fi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

fastfetch --config hypr
