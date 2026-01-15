#!/bin/bash

# Parse arguments
INPLACE_MODE=true
TMUX_MODE=false
BUILD_ONLY=false
for arg in "$@"; do
  case $arg in
    sandbox)
      INPLACE_MODE=false
      ;;
    tmux)
      TMUX_MODE=true
      ;;
    build)
      BUILD_ONLY=true
      ;;
  esac
done

echo "🚀 Starting OpenCode..."

WORKTREE_NAME=$(pwd | sed 's/[^a-zA-Z0-9_-]/_/g')

# Check if current directory is a git repository and inplace mode is not enabled
if [ "$INPLACE_MODE" = false ] && git rev-parse --git-dir > /dev/null 2>&1; then
    # Get the repository root and current relative path
    REPO_ROOT=$(git rev-parse --show-toplevel)
    CURRENT_REL_PATH=$(realpath --relative-to="$REPO_ROOT" "$(pwd)")
    
    # Create worktree directory name based on repo root
    WORKTREE_DIR="$HOME/.opencode-projects/$WORKTREE_NAME"

    # Create worktree if it doesn't exist
    if [ ! -d "$WORKTREE_DIR" ]; then
        mkdir -p "$HOME/.opencode-projects"
        
        # Check current branch situation
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        
        # Prompt for new branch if needed
        if [ -z "$CURRENT_BRANCH" ] || [ "$CURRENT_BRANCH" = "$MAIN_BRANCH" ] || [ "$CURRENT_BRANCH" = "HEAD" ]; then
            echo "Current branch: ${CURRENT_BRANCH:-"(detached HEAD)"}"
            read -p "Enter a new branch name (or press Enter to continue with current): " NEW_BRANCH
            if [ -n "$NEW_BRANCH" ]; then
                git worktree add "$WORKTREE_DIR" -b "$NEW_BRANCH"
                echo "Created new worktree with branch: $NEW_BRANCH"
            else
                git worktree add "$WORKTREE_DIR" HEAD
            fi
        else
            git worktree add "$WORKTREE_DIR" HEAD
        fi
    fi

    # Mount the worktree to /home/node/project, adjusting source path for subdirectory context
    if [ "$CURRENT_REL_PATH" != "." ]; then
        # When in a subdirectory, mount the subdirectory directly
        PROJECT_MOUNT="$WORKTREE_DIR/$CURRENT_REL_PATH:/home/node/project"
        echo "📁 Preserving subdirectory context: $CURRENT_REL_PATH"
    else
        # When at repo root, mount the entire worktree
        PROJECT_MOUNT="$WORKTREE_DIR:/home/node/project"
    fi
else
    PROJECT_MOUNT="$(pwd):/home/node/project"
fi

PROJECT_MOUNT="$PROJECT_MOUNT/$WORKTREE_NAME"

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="opencode$WORKTREE_NAME"

# Build the docker image
build_image() {
  echo "🐳 Building OpenCode image..."
  docker build --no-cache -t opencode:latest $SCRIPT_DIR -f "$SCRIPT_DIR/Dockerfile"
  echo "✅ OpenCode image built successfully"
}

# Build the docker command array
build_docker_command() {
  # Check if container already exists
  if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
    echo "docker exec -it $CONTAINER_NAME /bin/bash"
    return 0
  fi
  
  local docker_cmd=(docker run --rm --memory=3g --memory-swap=3g --name "$CONTAINER_NAME")
  docker_cmd+=(-it)
  docker_cmd+=(-v opencode-share:/home/node/.local/share:rw)
  docker_cmd+=(-v "$PROJECT_MOUNT")
  docker_cmd+=(-v "$SCRIPT_DIR/opencode:/home/node/.config/opencode")
  docker_cmd+=(-v "$HOME/.config/nvim:/home/node/.config/nvim")
  if [ -f "$HOME/.nvimrc" ]; then
    docker_cmd+=(-v "$HOME/.nvimrc:/home/node/.nvimrc")
  fi
  docker_cmd+=(-w "/home/node/project/$WORKTREE_NAME")
  docker_cmd+=(-u 1000:1000)
  docker_cmd+=(opencode:latest)
  
  echo "${docker_cmd[@]}"
}

# Start the container
start_container() {
  # Check if image exists, build if needed
  if ! docker image inspect opencode:latest >/dev/null 2>&1; then
    build_image
  fi

  local docker_cmd
  docker_cmd=$(build_docker_command)
  
  # Check if we got an exec command
  case $docker_cmd in
    "docker exec"*)
      echo "🔍 Container ${CONTAINER_NAME} already exists, connecting..."
      ;;
  esac
  
  # Execute the docker command
  eval "$docker_cmd"
}

set -ex

# Handle build-only mode
if [ "$BUILD_ONLY" = true ]; then
  build_image
  exit 0
fi

# Handle tmux mode
if [ "$TMUX_MODE" = true ]; then
  if ! command -v tmux &> /dev/null; then
    echo "❌ tmux is not installed. Please install tmux first."
    exit 1
  fi

  if [ "$INPLACE_MODE" = true ]; then
    WORKTREE_PATH="$(pwd)"
  else
    WORKTREE_PATH="$WORKTREE_DIR"
    if [ ! -d "$WORKTREE_DIR" ]; then
      echo "❌ Worktree directory not found. Run without tmux mode first to set up the worktree."
      exit 1
    fi
  fi

  echo "🪟 Creating tmux window with two panes..."
  
  # Build the docker command once
  docker_cmd=$(build_docker_command)
  
  # Check if container exists for tmux mode
  case $docker_cmd in
    "docker exec"*)
      echo "🔍 Container ${CONTAINER_NAME} already exists, connecting in tmux..."
      ;;
  esac

  # Create a new tmux window or session
  if [ -n "$TMUX" ]; then
    # Already in tmux, create new window
    tmux new-window -n "opencode-$WORKTREE_NAME"
    WINDOW_TARGET="opencode-$WORKTREE_NAME"
  else
    # Start new tmux session
    tmux new-session -d -s "opencode-$WORKTREE_NAME" -n "opencode-$WORKTREE_NAME"
    WINDOW_TARGET="opencode-$WORKTREE_NAME:opencode-$WORKTREE_NAME"
  fi

  # Split the newly created window vertically
  tmux split-window -h -t "$WINDOW_TARGET"

  # Left pane: shell in worktree directory
  tmux send-keys -t "$WINDOW_TARGET.0" "cd '$WORKTREE_PATH'" C-m
  tmux send-keys -t "$WINDOW_TARGET.0" "clear" C-m

  # Right pane: opencode container
  tmux send-keys -t "$WINDOW_TARGET.1" "$docker_cmd" C-m

  # Attach to tmux if not already in tmux
  if [ -z "$TMUX" ]; then
    tmux attach-session -t "opencode-$WORKTREE_NAME"
  fi
  
  exit 0
fi

# Start container normally
start_container
