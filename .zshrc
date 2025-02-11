# zmodload zsh/zprof # debug zsh startup time
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export EDITOR=vim
export VISUAL=vim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export UID=$UID
export GID=$GID

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
if [[ "$OSTYPE" == "darwin"* ]]; then
    export ZSH_DISABLE_COMPFIX="true"
    export LC_CTYPE="en_US.UTF-8"
    plugins=(git colored-man-pages macos zsh-syntax-highlighting)
    export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/$USER/android-sdk/platform-tools:/Users/$USER/android-sdk/tools:/Users/$USER/local_bin:/Users/$USER/bin:/Users/$USER/android-ndk:/Users/$USER/Library/Python/2.7/bin:/usr/local/go/bin:$HOME/go/bin"
else
    plugins=(git colored-man-pages zsh-syntax-highlighting)
    export PATH=$PATH:$HOME/unix_scripts:$HOME/android/platform-tools:$HOME/.local/bin:/usr/local/go/bin:$HOME/go/bin
fi

# User configuration

#export SITEPACKPATH=$(python -c "import os; print(os.path.dirname(os.__file__))")/site-packages


if [[ -f $HOME/.tmux_new_dir ]]; then
    export TMUX_NEW_DIR=$(cat $HOME/.tmux_new_dir)
else
    export TMUX_NEW_DIR=$HOME
fi

source $ZSH/oh-my-zsh.sh
##source /home/$USER/.logins/aliases.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
#/ alias ohmyzsh="mate ~/.oh-my-zsh"
alias ls="ls -Glah --color=auto"
alias gonvim="~/gonvim/gonvim.sh"
alias vim="nvim"

if [[ -f $HOME/.prod-kubeconfig.yaml ]]; then
    alias kprod="kubectl --kubeconfig ~/.prod-kubeconfig.yaml"
else
	alias kprod="echo 'No prod kubeconfig found'"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Turso
    export PATH="$HOME/.turso:$PATH"
    eval "$(fnm env --use-on-cd --shell zsh)"
fi
# zprof # debug zsh startup time
