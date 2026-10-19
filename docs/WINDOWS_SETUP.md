# Windows 11 development setup

All tools below have free versions. **No subscription and no additional online account required.**

## Prerequisites
1. **Git for Windows**: https://git-scm.com/download/win (or GitHub Desktop from https://desktop.github.com/).
2. **Node.js LTS** with npm: https://nodejs.org/en/download
3. **Rust / rustup** using the **stable MSVC** toolchain: https://rustup.rs/
4. **Visual Studio Build Tools**, select **Desktop development with C++** workload (MSVC + Windows 10/11 SDK): https://visualstudio.microsoft.com/visual-cpp-build-tools/
5. **Microsoft Edge WebView2 Runtime**: present on most supported Windows 10/11 devices; install only if missing: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
6. **VS Code** is recommended but optional: https://code.visualstudio.com/

Authoritative instructions: https://v2.tauri.app/start/prerequisites/

## Verify in PowerShell (new window after installs)
```powershell
git --version
node --version
npm --version
rustc --version
cargo --version
rustup show
```
The active Rust toolchain should end in `-pc-windows-msvc`. If it does not, run `rustup default stable-msvc`.

## Clone project
```powershell
mkdir C:\Dev -ErrorAction SilentlyContinue
cd C:\Dev
git clone https://github.com/briang7165/Game-Dock.git
cd Game-Dock
```
If the repository is private later, authenticate with your existing GitHub account through Git Credential Manager or GitHub Desktop.

## Run launcher
Double-click `START_GAME_DOCK_DEV.bat`, or:
```powershell
cd C:\Dev\Game-Dock\launcher
npm install
npm run tauri dev
```
The browser-only layout preview is `npm run dev`. Game launching and opening native folders need the actual Tauri desktop window.

## Prove game launching
From the repo root double-click `INSTALL_HARBOR_TEST.bat`. It uses `rustc` to build a small MessageBox Windows program and installs it under the local Game Dock game folder. Launch Game Dock, go to the Library tab, click **Refresh**, then **Play** Harbor Test. Confirm that a message box appears.

## Build installer
Double-click `BUILD_WINDOWS_INSTALLER.bat` or run `npm run tauri build` inside `launcher`.
Installer location: `launcher\src-tauri\target\release\bundle\nsis`.

## Troubleshooting
- `cargo` missing: restart Terminal and check rustup installation.
- `link.exe` missing: install MSVC C++ Build Tools and Windows SDK.
- WebView2 missing: install/repair WebView2 Evergreen Runtime.
- `npm` missing: install Node.js LTS and restart Terminal.
- Blank library: the sample test program has not been built/installed, or manifest and executable are not in matching subfolder.
- Avoid running builds inside OneDrive-synced folders; sync project notes/archives there instead.
