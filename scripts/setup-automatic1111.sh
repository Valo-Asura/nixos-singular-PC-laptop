#!/usr/bin/env bash
set -euo pipefail

# 1. Define paths
TARGET_DIR="/home/asura/stable-diffusion-webui"
echo "=== Setting up Stable Diffusion WebUI in $TARGET_DIR ==="

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Touch setup lockfile
touch .setup_running
echo "Status: Starting setup..." > setup_status.txt

# 2. Write shell.nix for NixOS FHS environment
echo "Creating shell.nix..."
cat << 'EOF' > shell.nix
{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSEnv {
  name = "stable-diffusion-webui-env";
  targetPkgs = pkgs: with pkgs; [
    git
    git-lfs
    wget
    curl
    pkg-config
    cmake
    gnumake
    gcc
    stdenv.cc.cc.lib

    python311
    bc

    glib
    glibc
    libGL
    libglvnd
    opencv
    libx11
    libxext
    libxrender
    libxtst
    libxi
    zlib
    openssl
    libxcrypt
    gperftools

    linuxPackages.nvidia_x11
    cudatoolkit
  ];

  profile = ''
    export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
    export CUDA_PATH=${pkgs.cudatoolkit}
  '';

  runScript = "bash";
})
EOF

# 3. Create start-webui.sh and start-webui.fish immediately so they exist right away
echo "Creating start-webui.sh launcher..."
cat << 'EOF' > start-webui.sh
#!/usr/bin/env bash
if [ -f .setup_running ]; then
  echo "=========================================================="
  echo "Stable Diffusion WebUI is still downloading models in the background."
  if [ -f setup_status.txt ]; then
    cat setup_status.txt
  else
    echo "Starting setup..."
  fi
  echo "----------------------------------------------------------"
  echo "To view full log details: tail -n 20 setup.log"
  echo "=========================================================="
  exit 1
fi
FHS_PATH=\$({ NIXPKGS_ALLOW_UNFREE=1 nix-build shell.nix --no-out-link; } || env NIXPKGS_ALLOW_UNFREE=1 nix-build shell.nix --no-out-link)
env PIP_CONSTRAINT="\$(pwd)/pip-constraints.txt" STABLE_DIFFUSION_REPO="https://github.com/joypaul162/Stability-AI-stablediffusion.git" \$FHS_PATH/bin/stable-diffusion-webui-env -c "./webui.sh --medvram --xformers --enable-insecure-extension-access --listen"
EOF
chmod +x start-webui.sh

echo "Creating start-webui.fish launcher..."
cat << 'EOF' > start-webui.fish
#!/usr/bin/env fish
if test -f .setup_running
  echo "=========================================================="
  echo "Stable Diffusion WebUI is still downloading models in the background."
  if test -f setup_status.txt
    cat setup_status.txt
  else
    echo "Starting setup..."
  end
  echo "----------------------------------------------------------"
  echo "To view full log details: tail -n 20 setup.log"
  echo "=========================================================="
  exit 1
end
set -l FHS_PATH (env NIXPKGS_ALLOW_UNFREE=1 nix-build shell.nix --no-out-link)
env PIP_CONSTRAINT=(pwd)/pip-constraints.txt STABLE_DIFFUSION_REPO=https://github.com/joypaul162/Stability-AI-stablediffusion.git \$FHS_PATH/bin/stable-diffusion-webui-env -c "./webui.sh --medvram --xformers --enable-insecure-extension-access --listen"
EOF
chmod +x start-webui.fish

# Start the background progress monitor loop
(
  while [ -f .setup_running ]; do
    if [ -f "models/Stable-diffusion/Realistic_Vision_V6.0_NV_B1.safetensors" ] && [ "$(stat -c%s "models/Stable-diffusion/Realistic_Vision_V6.0_NV_B1.safetensors" 2>/dev/null || echo 0)" -lt 4265096996 ]; then
      SZ=$(stat -c%s "models/Stable-diffusion/Realistic_Vision_V6.0_NV_B1.safetensors" 2>/dev/null || echo 0)
      PCT=$((SZ * 100 / 4265096996))
      echo "Status: Downloading Realistic Vision V6.0 B1 ($((SZ / 1024 / 1024)) MB / 4067 MB, ${PCT}%)" > setup_status.txt
    elif [ -f "models/VAE/vae-ft-mse-840000-ema-pruned.safetensors" ] && [ "$(stat -c%s "models/VAE/vae-ft-mse-840000-ema-pruned.safetensors" 2>/dev/null || echo 0)" -lt 334641190 ]; then
      SZ=$(stat -c%s "models/VAE/vae-ft-mse-840000-ema-pruned.safetensors" 2>/dev/null || echo 0)
      PCT=$((SZ * 100 / 334641190))
      echo "Status: Downloading Recommended VAE ($((SZ / 1024 / 1024)) MB / 319 MB, ${PCT}%)" > setup_status.txt
    elif [ -f "models/insightface/inswapper_128.onnx" ] && [ "$(stat -c%s "models/insightface/inswapper_128.onnx" 2>/dev/null || echo 0)" -lt 554253681 ]; then
      SZ=$(stat -c%s "models/insightface/inswapper_128.onnx" 2>/dev/null || echo 0)
      PCT=$((SZ * 100 / 554253681))
      echo "Status: Downloading Face Swap Model ($((SZ / 1024 / 1024)) MB / 528 MB, ${PCT}%)" > setup_status.txt
    fi
    sleep 1
  done
) &
MONITOR_PID=$!

# Redirect stdout and stderr of the setup steps to setup.log using process substitution (does not replace process)
exec > >(stdbuf -oL -eL tee -i setup.log) 2>&1

# 4. Clone Stable Diffusion WebUI if not already cloned
if [ ! -d ".git" ]; then
  echo "Initializing git and pulling AUTOMATIC1111 stable-diffusion-webui..."
  echo "Status: Initializing git and pulling WebUI..." > setup_status.txt
  git init
  git remote add origin https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
  git fetch --depth 1
  git checkout -f master || git checkout -f main
else
  echo "WebUI repository already initialized, skipping pull."
fi

# 5. Clone ReActor extension (using the SFW repository)
echo "Setting up ReActor extension..."
echo "Status: Cloning ReActor extension..." > setup_status.txt
mkdir -p extensions
if [ ! -d "extensions/sd-webui-reactor" ]; then
  git clone https://github.com/Gourieff/sd-webui-reactor-sfw.git extensions/sd-webui-reactor
else
  echo "ReActor extension already installed."
fi

# 6. Create directories for models
mkdir -p models/Stable-diffusion
mkdir -p models/VAE
mkdir -p models/insightface

# 7. Download models with robustness checks
echo "Checking/Downloading Realistic Vision V6.0 B1 (No VAE)..."
RV_PATH="models/Stable-diffusion/Realistic_Vision_V6.0_NV_B1.safetensors"
if [ -f "$RV_PATH" ]; then
  FILE_SIZE=$(stat -c%s "$RV_PATH")
  if [ "$FILE_SIZE" -lt 4000000000 ]; then
    echo "Incomplete Realistic Vision detected ($FILE_SIZE bytes). Redownloading..."
    rm -f "$RV_PATH"
  fi
fi

if [ ! -f "$RV_PATH" ]; then
  wget --progress=dot:giga -O "$RV_PATH" \
    "https://huggingface.co/SG161222/Realistic_Vision_V6.0_B1_noVAE/resolve/main/Realistic_Vision_V6.0_NV_B1.safetensors"
else
  echo "Realistic Vision V6.0 B1 is already downloaded and complete."
fi

echo "Checking/Downloading Recommended VAE..."
VAE_PATH="models/VAE/vae-ft-mse-840000-ema-pruned.safetensors"
if [ -f "$VAE_PATH" ]; then
  FILE_SIZE=$(stat -c%s "$VAE_PATH")
  if [ "$FILE_SIZE" -lt 300000000 ]; then
    echo "Incomplete VAE detected ($FILE_SIZE bytes). Redownloading..."
    rm -f "$VAE_PATH"
  fi
fi

if [ ! -f "$VAE_PATH" ]; then
  wget --progress=dot:giga -O "$VAE_PATH" \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
else
  echo "VAE is already downloaded and complete."
fi

echo "Checking/Downloading Face Swap Model (inswapper_128.onnx)..."
SWAP_PATH="models/insightface/inswapper_128.onnx"
if [ -f "$SWAP_PATH" ]; then
  FILE_SIZE=$(stat -c%s "$SWAP_PATH")
  if [ "$FILE_SIZE" -lt 500000000 ]; then
    echo "Incomplete face swap model detected ($FILE_SIZE bytes). Redownloading..."
    rm -f "$SWAP_PATH"
  fi
fi

if [ ! -f "$SWAP_PATH" ]; then
  wget --progress=dot:giga -O "$SWAP_PATH" \
    "https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx"
else
  echo "Face swap model is already downloaded and complete."
fi

# 8. Setup Z-Image-Turbo (Diffusers Model)
echo "Downloading Z-Image-Turbo..."
echo "Status: Downloading Z-Image-Turbo (Cloning git repository)..." > setup_status.txt
mkdir -p models/diffusers
if [ ! -d "models/diffusers/Z-Image-Turbo" ]; then
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://huggingface.co/Tongyi-MAI/Z-Image-Turbo models/diffusers/Z-Image-Turbo || echo "Could not clone Z-Image-Turbo automatically. You may need to download it manually."
else
  echo "Z-Image-Turbo already cloned."
fi

# Remove lockfile and status file once everything is finished
rm -f .setup_running
rm -f setup_status.txt

echo "=== Setup Complete ==="
echo "To launch the WebUI, run:"
echo "  cd $TARGET_DIR && ./start-webui.fish"
