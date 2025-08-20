FROM node:24-slim

RUN apt-get update && apt-get install -y git curl bash fzf ripgrep unzip wget ca-certificates gcc

# Install latest Neovim from official Linux tarball
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
    tar xzvf nvim-linux-x86_64.tar.gz && \
    mv nvim-linux-x86_64 /opt/nvim && \
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz

RUN npm i -g opencode-ai@latest

USER node

ENV EDITOR=nvim

RUN mkdir /home/node/project
RUN mkdir /home/node/.opencode
RUN mkdir -p /home/node/.local/share/

WORKDIR /home/node/project

ENTRYPOINT ["/usr/local/bin/opencode"]
