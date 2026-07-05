#!/bin/bash
# androdart_studio — First-launch setup script
# Runs inside proot container on first app start
# Features: resume support, skip-on-fail, weighted progress

set -e

HOME_DIR="/home/user"
SETUP_MARKER="$HOME_DIR/.setup_complete"
LOG_FILE="$HOME_DIR/setup.log"

# Progress tracking (weighted by download size)
TOTAL_WEIGHT=100
CURRENT_WEIGHT=0

update_progress() {
    local weight=$1
    CURRENT_WEIGHT=$((CURRENT_WEIGHT + weight))
    echo "[PROGRESS] $(echo "scale=2; $CURRENT_WEIGHT / $TOTAL_WEIGHT" | bc)"
}

# Resume check
if [ -f "$SETUP_MARKER" ]; then
    echo "[COMPLETE] Setup already complete"
    exit 0
fi

echo "[PROGRESS] 0"

# ============================================================================
# Step 1: Base packages (weight: 2)
# ============================================================================
install_base() {
    echo "[STEP] Installing base packages..."
    
    if command -v git &> /dev/null && command -v wget &> /dev/null; then
        echo "[SKIP] Base packages already installed"
        update_progress 2
        return 0
    fi
    
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE" || true
    apt-get install -y -qq curl wget git unzip xz-utils 2>&1 | tee -a "$LOG_FILE" || true
    
    echo "[SUCCESS] Base packages installed"
    update_progress 2
}

# ============================================================================
# Step 2: JDK 17 (weight: 25)
# ============================================================================
install_jdk() {
    echo "[STEP] Installing JDK 17..."
    
    if [ -f "$HOME_DIR/jdk/bin/java" ]; then
        echo "[SKIP] JDK already installed"
        update_progress 25
        return 0
    fi
    
    echo "[LOG] Downloading OpenJDK 17..."
    if ! wget -q --show-progress -O /tmp/jdk17.tar.gz \
        "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.12%2B7/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.12_7.tar.gz" \
        2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] JDK download failed, skipping"
        update_progress 25
        return 0
    fi
    
    echo "[LOG] Extracting JDK..."
    if ! tar xzf /tmp/jdk17.tar.gz -C "$HOME_DIR" 2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] JDK extraction failed, skipping"
        rm -f /tmp/jdk17.tar.gz
        update_progress 25
        return 0
    fi
    
    # Handle different directory names
    if [ -d "$HOME_DIR/jdk-17.0.12+7" ]; then
        mv "$HOME_DIR/jdk-17.0.12+7" "$HOME_DIR/jdk"
    elif [ -d "$HOME_DIR/jdk-17.0.12" ]; then
        mv "$HOME_DIR/jdk-17.0.12" "$HOME_DIR/jdk"
    fi
    
    rm -f /tmp/jdk17.tar.gz
    
    export JAVA_HOME="$HOME_DIR/jdk"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo "[SUCCESS] JDK 17 installed"
    update_progress 25
}

# ============================================================================
# Step 3: Flutter SDK (weight: 60)
# ============================================================================
install_flutter() {
    echo "[STEP] Installing Flutter SDK..."
    
    if [ -f "$HOME_DIR/flutter/bin/flutter" ]; then
        echo "[SKIP] Flutter already installed"
        update_progress 60
        return 0
    fi
    
    echo "[LOG] Downloading Flutter 3.44.4..."
    if ! wget -q --show-progress -O /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz" \
        2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] Flutter download failed, skipping"
        update_progress 60
        return 0
    fi
    
    echo "[LOG] Extracting Flutter SDK (this may take a while)..."
    if ! tar xf /tmp/flutter.tar.xz -C "$HOME_DIR" 2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] Flutter extraction failed, skipping"
        rm -f /tmp/flutter.tar.xz
        update_progress 60
        return 0
    fi
    
    rm -f /tmp/flutter.tar.xz
    
    export PATH="$HOME_DIR/flutter/bin:$PATH"
    
    echo "[SUCCESS] Flutter SDK installed"
    update_progress 60
}

# ============================================================================
# Step 4: Patch Flutter for ARM64 (weight: 5)
# ============================================================================
patch_flutter() {
    echo "[STEP] Patching Flutter for ARM64..."
    
    if [ ! -d "$HOME_DIR/flutter" ]; then
        echo "[SKIP] Flutter not installed, skipping patch"
        update_progress 5
        return 0
    fi
    
    # Fix platform detection in shared.dart
    SHARED_DART="$HOME_DIR/flutter/bin/internal/shared.dart"
    if [ -f "$SHARED_DART" ]; then
        sed -i "s/Platform.operatingSystem == 'linux'/Platform.operatingSystem == 'linux' || Platform.operatingSystem == 'android'/g" "$SHARED_DART" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Fix dart executable permission
    chmod +x "$HOME_DIR/flutter/bin/cache/dart-sdk/bin/dart" 2>/dev/null || true
    chmod +x "$HOME_DIR/flutter/bin/dart" 2>/dev/null || true
    
    echo "[SUCCESS] Flutter patched for ARM64"
    update_progress 5
}

# ============================================================================
# Step 5: Android SDK (weight: 5)
# ============================================================================
install_android_sdk() {
    echo "[STEP] Installing Android SDK..."
    
    if [ -f "$HOME_DIR/android-sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
        echo "[SKIP] Android SDK already installed"
        update_progress 5
        return 0
    fi
    
    echo "[LOG] Downloading Android SDK command-line tools..."
    if ! wget -q --show-progress -O /tmp/cmdline-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
        2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] Android SDK download failed, skipping"
        update_progress 5
        return 0
    fi
    
    echo "[LOG] Extracting Android SDK..."
    mkdir -p "$HOME_DIR/android-sdk/cmdline-tools" 2>&1 | tee -a "$LOG_FILE" || true
    
    if ! unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools 2>&1 | tee -a "$LOG_FILE"; then
        echo "[FAIL] Android SDK extraction failed, skipping"
        rm -f /tmp/cmdline-tools.zip
        rm -rf /tmp/cmdline-tools
        update_progress 5
        return 0
    fi
    
    # Move to correct location
    if [ -d "/tmp/cmdline-tools/cmdline-tools" ]; then
        mv /tmp/cmdline-tools/cmdline-tools "$HOME_DIR/android-sdk/cmdline-tools/latest"
    fi
    
    rm -f /tmp/cmdline-tools.zip
    rm -rf /tmp/cmdline-tools
    
    export ANDROID_HOME="$HOME_DIR/android-sdk"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    
    echo "[SUCCESS] Android SDK installed"
    update_progress 5
}

# ============================================================================
# Step 6: Build tools & aapt2 (weight: 2)
# ============================================================================
install_build_tools() {
    echo "[STEP] Installing build tools..."
    
    if [ -f "$HOME_DIR/android-sdk/build-tools/35.0.1/aapt2" ]; then
        echo "[SKIP] Build tools already installed"
        update_progress 2
        return 0
    fi
    
    # Install build tools via sdkmanager if available
    if [ -f "$HOME_DIR/android-sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
        export JAVA_HOME="$HOME_DIR/jdk"
        export ANDROID_HOME="$HOME_DIR/android-sdk"
        export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
        
        yes | sdkmanager --licenses > /dev/null 2>&1 || true
        sdkmanager "build-tools;35.0.1" "platform-tools" "platforms;android-35" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    echo "[SUCCESS] Build tools installed"
    update_progress 2
}

# ============================================================================
# Step 7: Setup storage symlinks (weight: 1)
# ============================================================================
setup_storage() {
    echo "[STEP] Setting up storage symlinks..."
    
    mkdir -p "$HOME_DIR/storage" 2>/dev/null || true
    
    # Create symlinks (ignore errors if target doesn't exist)
    ln -sf /storage/emulated/0 "$HOME_DIR/storage/shared" 2>/dev/null || true
    ln -sf /storage/emulated/0/Download "$HOME_DIR/storage/downloads" 2>/dev/null || true
    ln -sf /storage/emulated/0/DCIM "$HOME_DIR/storage/dcim" 2>/dev/null || true
    ln -sf /storage/emulated/0/Music "$HOME_DIR/storage/music" 2>/dev/null || true
    ln -sf /storage/emulated/0/Pictures "$HOME_DIR/storage/pictures" 2>/dev/null || true
    ln -sf /storage/emulated/0/Movies "$HOME_DIR/storage/movies" 2>/dev/null || true
    
    echo "[SUCCESS] Storage symlinks created"
    update_progress 1
}

# ============================================================================
# Step 8: Configure Git (weight: 1)
# ============================================================================
configure_git() {
    echo "[STEP] Configuring Git..."
    
    if ! command -v git &> /dev/null; then
        echo "[SKIP] Git not installed, skipping config"
        update_progress 1
        return 0
    fi
    
    git config --global user.name "Flutter Developer" 2>&1 | tee -a "$LOG_FILE" || true
    git config --global user.email "dev@androdart.studio" 2>&1 | tee -a "$LOG_FILE" || true
    git config --global init.defaultBranch main 2>&1 | tee -a "$LOG_FILE" || true
    
    echo "[SUCCESS] Git configured"
    update_progress 1
}

# ============================================================================
# Main execution
# ============================================================================
main() {
    echo "[STEP] Starting setup..."
    
    install_base
    install_jdk
    install_flutter
    patch_flutter
    install_android_sdk
    install_build_tools
    setup_storage
    configure_git
    
    # Mark setup complete
    touch "$SETUP_MARKER"
    
    echo "[PROGRESS] 1.0"
    echo "[COMPLETE] Setup finished successfully"
    
    # Print summary
    echo ""
    echo "========================================="
    echo "  Setup Complete!"
    echo "========================================="
    [ -f "$HOME_DIR/jdk/bin/java" ] && echo "  JDK: $(JAVA_HOME=$HOME_DIR/jdk $HOME_DIR/jdk/bin/java --version 2>&1 | head -1)"
    [ -f "$HOME_DIR/flutter/bin/flutter" ] && echo "  Flutter: $(PATH=$HOME_DIR/flutter/bin:$PATH flutter --version 2>&1 | head -1)"
    [ -f "$HOME_DIR/android-sdk/cmdline-tools/latest/bin/sdkmanager" ] && echo "  Android SDK: Installed"
    echo "========================================="
}

main "$@"
