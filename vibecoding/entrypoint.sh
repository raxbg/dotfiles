#!/bin/sh

# TODO: Adjust if running on mac to use the host.docker.internal address instead of the default docker gateway
export HOST_ADDR="172.17.0.1"

#export PATH=$PATH:/usr/local/go/bin

# Find and activate the closest .venv from current directory (searching downward)
#activate_venv() {
#    venv_path=$(find . -type d -name ".venv" 2>/dev/null | \
#        awk '{print length, $0}' | sort -n | cut -d' ' -f2- | head -1)
#    
#    if [ -n "$venv_path" ] && [ -f "$venv_path/bin/activate" ]; then
#        . "$venv_path/bin/activate"
#    fi
#}
#
#activate_venv

/usr/local/bin/opencode
