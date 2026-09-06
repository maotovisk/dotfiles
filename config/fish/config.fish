if status is-interactive
    # Commands to run in interactive sessions can go here
    fastfetch
end

# Garante que comandos como tr, basename e date funcionem
set -gx PATH /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin $PATH

alias paru="yay"
alias lg="lazygit"

# adições de binários locais
fish_add_path -g ~/.local/bin
fish_add_path -g /home/maoto/.dotnet
fish_add_path -g /home/maoto/.dotnet/tools
fish_add_path -g /home/maoto/.cargo/bin
fish_add_path -g /home/maoto/.config/herd-lite/bin
fish_add_path -g /opt/anaconda/condabin
fish_add_path -g /home/maoto/.local/share/JetBrains/Toolbox/scripts
fish_add_path -g /home/maoto/.spin/bin
fish_add_path -g /home/maoto/go/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# miniconda

#source ~/miniconda3/etc/fish/conf.d/conda.fish
# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/maoto/.lmstudio/bin
# End of LM Studio CLI section

# opencode
fish_add_path /home/maoto/.opencode/bin

fish_add_path /home/maoto/.spicetify

# ASDF configuration code
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims

set -x PHPENV_ROOT "/home/maoto/.phpenv"
if test -d "/home/maoto/.phpenv"
  set -x PATH "/home/maoto/.phpenv/bin" $PATH
  status --is-interactive; and . (phpenv init -|psub)
end

# Pi
fish_add_path "/home/maoto/.npm-global/bin"
