#!/bin/bash
# Bootstrap script to download and run QuBox staging automation
# This script downloads all required files and executes the staging process

set -e  # Exit on any error

echo "=========================================="
echo "QuBox Staging Bootstrap Script"
echo "=========================================="
echo ""

# Define URLs for the files to download
BASE_URL="https://raw.githubusercontent.com/ArahikZ/Qubox-staging/refs/heads/main"
EXPECT_SCRIPT_URL="${BASE_URL}/qubox_staging_v1.4.expect"
BIGFIX_SCRIPT_URL="${BASE_URL}/BigFix_QuBox_Install.sh"

# Create temp directory for downloads
WORK_DIR="/home/qu/"
cd "$WORK_DIR"

echo "Working directory: $WORK_DIR"
echo ""

# Step 1: Install expect if not present
echo "=== Step 1: Checking for expect ==="
if ! command -v expect &> /dev/null; then
    echo "expect not found. Installing..."
    sudo apt-get install -y expect
    echo "expect installed successfully."
else
    echo "expect is already installed."
fi
echo ""

# Step 2: Download the expect script
echo "=== Step 2: Downloading qubox_staging_v1.4.expect ==="
if curl --proto "=https" -fsSL -o qubox_staging_v1.4.expect "$EXPECT_SCRIPT_URL"; then
    chmod +x qubox_staging_v1.4.expect
    echo "✓ qubox_staging_v1.4.expect downloaded successfully."
else
    echo "✗ Failed to download expect script from $EXPECT_SCRIPT_URL"
    echo "  Attempting to use local copy if available..."
    if [ -f "/mnt/c/dev/Qu box Staging/qubox_staging_v1.4.expect" ]; then
        cp "/mnt/c/dev/Qu box Staging/qubox_staging_v1.4.expect" .
        chmod +x qubox_staging_v1.4.expect
        echo "✓ Using local copy of expect script."
    else
        echo "✗ No local copy found. Exiting."
        exit 1
    fi
fi
echo ""

# Step 3: Download BigFix_QuBox_Install.sh
echo "=== Step 3: Downloading BigFix_QuBox_Install.sh ==="
if curl --proto "=https" -fsSL -o BigFix_QuBox_Install.sh "$BIGFIX_SCRIPT_URL"; then
    chmod +x BigFix_QuBox_Install.sh
    echo "✓ BigFix_QuBox_Install.sh downloaded successfully."
else
    echo "✗ Failed to download from $BIGFIX_SCRIPT_URL"
    echo "  Attempting to use local copy if available..."
    if [ -f "/mnt/c/dev/Qu box Staging/BigFix_QuBox_Install.sh" ]; then
        cp "/mnt/c/dev/Qu box Staging/BigFix_QuBox_Install.sh" .
        chmod +x BigFix_QuBox_Install.sh
        echo "✓ Using local copy of BigFix_QuBox_Install.sh."
    else
        echo "✗ No local copy found. Exiting."
        exit 1
    fi
fi
echo ""

# Step 4: Run the expect script
echo "=========================================="
echo "All files ready. Starting QuBox staging..."
echo "=========================================="
echo ""

./qubox_staging_v1.4.expect

# Cleanup (optional - comment out if you want to keep files for debugging)
# echo ""
# echo "=== Cleaning up temporary files ==="
# cd /
# rm -rf "$WORK_DIR"
# echo "Cleanup complete."

echo ""
echo "=========================================="
echo "QuBox staging process completed!"
echo "=========================================="
