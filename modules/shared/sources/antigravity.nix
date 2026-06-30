{ lib, pkgs, ... }:

pkgs.symlinkJoin {
  name = "antigravity-with-playwright";
  paths = [ pkgs.antigravity ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    playwright_browsers="${
      pkgs.playwright-driver.browsers.override {
        withFirefox = false;
        withWebkit = false;
      }
    }"
    rm "$out/bin/antigravity"
    makeWrapper ${pkgs.antigravity}/bin/antigravity "$out/bin/antigravity" \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.playwright-test
          pkgs.nodejs
          pkgs.chromium
          pkgs.google-chrome
        ]
      } \
      --prefix NODE_PATH : ${pkgs.playwright-test}/lib/node_modules \
      --set PLAYWRIGHT_BROWSERS_PATH "$playwright_browsers" \
      --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1 \
      --set CHROME_BIN ${pkgs.google-chrome}/bin/google-chrome-stable \
      --set CHROME_PATH ${pkgs.google-chrome}/bin/google-chrome-stable \
      --set CHROME_EXECUTABLE ${pkgs.google-chrome}/bin/google-chrome-stable \
      --set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ${pkgs.google-chrome}/bin/google-chrome-stable
  '';
}
