#!/usr/bin/env bash
mkdir ~/nvim-tmp
cd ~/nvim-tmp
curl https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz -o nvim-linux64.tar.gz -s -L
tar xvzf nvim-linux64.tar.gz
mv nvim-linux64 ~/.local/share/nvim-linux64
ln -sf ~/.local/share/nvim-linux64/bin/nvim ~/.local/bin/nvim
cd -
rm -r ~/nvim-tmp
