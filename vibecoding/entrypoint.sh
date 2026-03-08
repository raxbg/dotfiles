#!/bin/sh

#export PATH=$PATH:/usr/local/go/bin

# Find and activate the closest .venv from current directory (searching downward)
activate_venv() {
    venv_path=$(find . -type d -name ".venv" 2>/dev/null | \
        awk '{print length, $0}' | sort -n | cut -d' ' -f2- | head -1)
    
    if [ -n "$venv_path" ] && [ -f "$venv_path/bin/activate" ]; then
        . "$venv_path/bin/activate"
    fi
}

#activate_venv

/usr/local/bin/opencode
