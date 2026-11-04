#!/bin/bash

# M5 Setup Script & Survival Toolkit
# Version: 2.0 (Optimized for 24GB Unified Memory)
# This script ensures your environment is tuned for the specific constraints of the M5 architecture.

set -e # Exit immediately if a command exits with a non-zero status.

echo "🚀 Starting M5 Environment Analysis & Setup..."

# 0. Pre-flight Checks (Dependencies)
echo "\n🔍 Checking Critical Dependencies..."
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Error: '$1' is not installed or not in PATH."
        echo "   Please install it before proceeding."
        exit 1
    else
        echo "✅ '$1' is installed."
    fi
}

check_dependency "ollama"
check_dependency "flutter"
# git is usually present if Xcode tools are installed, but good to check.
check_dependency "git" 

# 1. Check Ollama Models
echo "\n🧠 Checking Neural Engine (Ollama Models)..."

# Function to check and pull model
check_pull_model() {
    local model_name=$1
    if ollama list | grep -q "$model_name"; then
        echo "✅ Model '$model_name' found."
    else
        echo "⬇️ Model '$model_name' not found. Pulling (this may take a while)..."
        ollama pull "$model_name"
    fi
}

# The "Tactical Hand" (Coding)
check_pull_model "qwen2.5-coder:14b"
# The "Strategic Brain" (Writing/Docs)
check_pull_model "gemma2:9b"

# 2. Shell Configuration Generator
echo "\n🛠️  Generating Shell Configuration..."

CONFIG_CONTENT='
# --- M5 Survival Guide Config ---
# Environment Variables
export MODEL_CODE="qwen2.5-coder:14b"
export MODEL_WRITE="gemma2:9b"

# --- WORKFLOW MODES ---
# Mode Code: "The Tactical Hand"
# Strategy: Kill Writing Model -> Free VRAM -> Launch Coding Model
alias mode-code="echo \"🟢 ACTIVATING: Coding Mode (Tactical)...\" && ollama stop \$MODEL_WRITE && ollama run \$MODEL_CODE"

# Mode Write: "The Strategic Brain"
# Strategy: Kill Coding Model -> Free VRAM -> Launch Writing Model
alias mode-write="echo \"🔵 ACTIVATING: Writing Mode (Strategic)...\" && ollama stop \$MODEL_CODE && ollama run \$MODEL_WRITE"

# Mode Test: "The Simulation"
# Strategy: KILL ALL AI. Absolute priority to Simulators/Emulators.
# Warning: Do not run simulators with AI models loaded on 24GB RAM.
alias mode-test="echo \"🧹 CLEANUP: Killing ALL AI Models for Testing...\" && killall -9 ollama_llama_server 2>/dev/null || echo \"AI System Clean\""

# --- MAINTENANCE & HYGIENE ---
# Update your AI weapons. Run monthly.
alias m5-update="echo \"🔄 Updating M5 AI Models...\" && ollama pull \$MODEL_CODE && ollama pull \$MODEL_WRITE"

# Clean project artifacts to save disk space. Run quarterly or when low on space.
alias m5-clean="echo \"🧹 M5 Deep Clean...\" && flutter clean && echo \"suggest running: docker system prune\" && echo \"suggest running: ollama rm <unused_models>\""

# Quick health check
alias m5-check="echo \"🏥 M5 Health Check:\" && ollama list && flutter doctor"
# ------------------------------
'

# Check if configuration exists in .zshrc
RC_FILE="$HOME/.zshrc"
if grep -q "M5 Survival Guide Config" "$RC_FILE"; then
    echo "✅ M5 Configuration found in $RC_FILE."
    echo "💡 If you need to update it, remove the old block and run this script again."
else
    echo "⚠️  M5 Configuration not detected in $RC_FILE."
    echo "📋 Proposed Configuration:"
    echo "---------------------------------------------------"
    echo "$CONFIG_CONTENT"
    echo "---------------------------------------------------"
    
    # Auto-append prompt
    echo "ℹ️  Do you want to append this configuration to $RC_FILE? (Recommended)"
    read -r -p "Append to $RC_FILE? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        echo "$CONFIG_CONTENT" >> "$RC_FILE"
        echo "✅ Configuration appended to $RC_FILE."
        echo "🔄 Please run 'source $RC_FILE' or restart your terminal to apply changes."
    else
        echo "🚫 Skipped modifying $RC_FILE. You can add it manually later."
    fi
fi

# 3. The M5 Manifesto (Educational)
echo "\n📜 The M5 Manifesto (Survival Rules for 24GB Unified Memory)"
echo "------------------------------------------------------------"
echo "1. Exclusion is Absolute:   Code OR Test. Never both. Kill AI before Simulators."
echo "2. Tactics vs Strategy:     Use Local AI (Qwen) for code, Cloud (Gemini) for complex logic."
echo "3. Respect Cool-down:       Wait 2 seconds after mode-switching before launching Apps."
echo "4. Documentation is Truth:  AI generates code, but YOU define the specs (mode-write)."
echo "------------------------------------------------------------"

echo "\n🎉 Setup Complete. You are ready."
