FROM node:24-slim

RUN apt-get update && apt-get install -y git curl bash fzf ripgrep unzip vim

RUN npm i -g opencode-ai@latest

USER node

RUN mkdir /home/node/project
RUN mkdir /home/node/.opencode
RUN mkdir -p /home/node/.local/share/

WORKDIR /home/node/project

ENTRYPOINT ["/usr/local/bin/opencode"]
