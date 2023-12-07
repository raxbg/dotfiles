#!/bin/bash
export CURRENT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
LOCAL_BASHRC=$CURRENT_DIR/.bashrc

if [[ ! $(cat ~/.bashrc) == *"$LOCAL_BASHRC"* ]]; then
    if [[ -f $LOCAL_BASHRC ]]; then
        echo "Registering $LOCAL_BASHRC";
        echo "source $LOCAL_BASHRC" >> ~/.bashrc
    fi
fi

echo "Sourcing $LOCAL_BASHRC";
source $LOCAL_BASHRC

if ! which "go" >/dev/null 2>&1; then
    if [[ ! -d $GOPATH ]]; then
        mkdir -p $GOPATH
    fi

    if [[ -d $GODIR ]]; then
        rm -rf $GODIR
    fi

    curl -L https://go.dev/dl/go1.20.4.linux-amd64.tar.gz -o /tmp/go.tar.gz
    tar -C $(realpath -m $GODIR/..) -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
fi

if ! which "cargo" >/dev/null 2>&1; then
    if [[ ! -d $CARGO_HOME ]]; then
        mkdir -p $CARGO_HOME
    fi

    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
fi

if ! which "gcc" >/dev/null 2>&1; then
  sudo apt-get install gcc -y
fi