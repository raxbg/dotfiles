FROM node:24-slim

RUN apt-get update && apt-get install -y git curl bash fzf ripgrep unzip wget ca-certificates gcc

# Install latest Neovim from official Linux tarball with architecture detection
RUN ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) NVIM_ARCH="x86_64" ;; \
        aarch64) NVIM_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz && \
    tar xzvf nvim-linux-${NVIM_ARCH}.tar.gz && \
    mv nvim-linux-${NVIM_ARCH} /opt/nvim && \
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-${NVIM_ARCH}.tar.gz

RUN npm i -g opencode-ai@latest

USER node

ENV EDITOR=nvim

RUN mkdir /home/node/project
RUN mkdir /home/node/.opencode
RUN mkdir -p /home/node/.local/share/

WORKDIR /home/node/project

ENTRYPOINT ["/usr/local/bin/opencode"]
