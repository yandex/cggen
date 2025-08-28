#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

HOOKS_DIR="git-hooks"
GIT_HOOKS_DIR=".git/hooks"

mkdir -p "$GIT_HOOKS_DIR"

for hook in "$HOOKS_DIR"/*; do
    if [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        target="$GIT_HOOKS_DIR/$hook_name"
        
        if [ -e "$target" ] || [ -L "$target" ]; then
            rm "$target"
        fi
        
        ln -s "$SCRIPT_DIR/$HOOKS_DIR/$hook_name" "$target"
    fi
done
