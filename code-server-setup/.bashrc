export CURRENT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
export GODIR=$CURRENT_DIR/go
export GOPATH=$CURRENT_DIR/gopath
export CARGO_HOME=$CURRENT_DIR/cargo
export NVIMDIR=$CURRENT_DIR/nvim
export PATH=$PATH:$GODIR/bin:$CARGO_HOME/bin:$NVIMDIR/bin
