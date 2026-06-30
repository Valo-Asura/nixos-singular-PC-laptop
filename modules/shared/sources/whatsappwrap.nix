{ pkgs, ... }:

let
  whatsappWeb = pkgs.writeShellScriptBin "whatsapp-web" ''
    unset ELECTRON_RUN_AS_NODE ELECTRON_NO_ATTACH_CONSOLE GTK_MODULES

    export FONTCONFIG_FILE=/etc/fonts/fonts.conf
    export FONTCONFIG_PATH=/etc/fonts

    # Keep this chat webapp on the Intel/Mesa path. Chromium/Dawn can otherwise
    # wake the NVIDIA dGPU for WebGPU/Vulkan probes and print noisy adapter logs.
    export DRI_PRIME=0
    export __NV_PRIME_RENDER_OFFLOAD=0
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json

    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --app=https://web.whatsapp.com \
      --class=whatsapp-web \
      --name=whatsapp-web \
      --no-first-run \
      --ozone-platform=wayland \
      --use-gl=egl \
      --use-angle=gl \
      --disable-features=WebGPU,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE \
      --disable-logging \
      --log-level=3 \
      "$@"
  '';

  whatsappWebDesktop = pkgs.makeDesktopItem {
    name = "whatsapp-web";
    desktopName = "WhatsApp";
    genericName = "Messaging";
    comment = "Open WhatsApp Web";
    exec = "whatsapp-web";
    icon = "whatsapp";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    startupWMClass = "whatsapp-web";
  };
in
{
  inherit whatsappWeb whatsappWebDesktop;
}
