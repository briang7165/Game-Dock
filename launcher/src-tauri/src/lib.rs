use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use tauri::Manager;

const DOCK_VERSION: &str = "0.1.0";

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
struct GameManifest {
    schema_version: u32,
    id: String,
    name: String,
    version: String,
    executable: String,
    genre: Option<String>,
    description: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
struct GameEntry {
    id: String,
    name: String,
    version: String,
    executable: String,
    genre: Option<String>,
    description: Option<String>,
    ready: bool,
}

#[derive(Serialize)]
struct DockInfo {
    version: &'static str,
    games_dir: String,
    os: &'static str,
}

fn valid_id(id: &str) -> bool {
    !id.is_empty() && id.len() <= 64 &&
    !id.starts_with('-') && !id.ends_with('-') &&
    !id.contains("--") &&
    id.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
}

fn valid_executable(file: &str) -> bool {
    !file.is_empty() && file.len() <= 128 &&
    file.to_ascii_lowercase().ends_with(".exe") &&
    !file.starts_with('.') && !file.ends_with(' ') &&
    file.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '_' | '-' | ' ' | '.')) &&
    Path::new(file).file_name().and_then(|name| name.to_str()) == Some(file)
}

fn games_directory(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    let path = app.path().app_data_dir().map_err(|e| e.to_string())?.join("games");
    fs::create_dir_all(&path).map_err(|e| e.to_string())?;
    Ok(path)
}

fn resolve_executable(folder: &Path, manifest: &GameManifest) -> Option<PathBuf> {
    if !valid_executable(&manifest.executable) { return None; }
    let folder_real = fs::canonicalize(folder).ok()?;
    let executable_real = fs::canonicalize(folder.join(&manifest.executable)).ok()?;
    if !executable_real.starts_with(&folder_real) || !executable_real.is_file() { return None; }
    Some(executable_real)
}

fn read_manifest(folder: &Path) -> Option<GameManifest> {
    let raw = fs::read_to_string(folder.join("game.json")).ok()?;
    if raw.len() > 16_384 { return None; }
    let manifest: GameManifest = serde_json::from_str(&raw).ok()?;
    let folder_name = folder.file_name()?.to_str()?;
    if manifest.schema_version != 1 || !valid_id(&manifest.id) || manifest.id != folder_name ||
       manifest.name.trim().is_empty() || manifest.name.len() > 100 || manifest.version.trim().is_empty() ||
       manifest.version.len() > 40 || !valid_executable(&manifest.executable) ||
       manifest.genre.as_ref().is_some_and(|g| g.len() > 60) ||
       manifest.description.as_ref().is_some_and(|d| d.len() > 400) {
        return None;
    }
    Some(manifest)
}

#[tauri::command]
fn list_games(app: tauri::AppHandle) -> Result<Vec<GameEntry>, String> {
    let root = games_directory(&app)?;
    let mut games = Vec::new();
    for item in fs::read_dir(root).map_err(|e| e.to_string())?.flatten() {
        let folder = item.path();
        if !folder.is_dir() || folder.is_symlink() { continue; }
        if let Some(game) = read_manifest(&folder) {
            let ready = resolve_executable(&folder, &game).is_some();
            games.push(GameEntry {
                id: game.id, name: game.name, version: game.version,
                executable: game.executable, genre: game.genre,
                description: game.description, ready,
            });
        }
    }
    games.sort_by_key(|game| game.name.to_lowercase());
    Ok(games)
}

#[tauri::command]
fn launch_game(app: tauri::AppHandle, id: String) -> Result<(), String> {
    if !valid_id(&id) { return Err("Invalid game ID".into()); }
    let folder = games_directory(&app)?.join(&id);
    if !folder.is_dir() || folder.is_symlink() { return Err("Game not installed".into()); }
    let manifest = read_manifest(&folder).ok_or("Game manifest is invalid")?;
    let executable = resolve_executable(&folder, &manifest)
        .ok_or("Game executable missing or outside its installation directory")?;
    Command::new(&executable)
        .current_dir(&folder)
        .spawn()
        .map_err(|e| format!("Could not start game: {e}"))?;
    Ok(())
}

#[tauri::command]
fn open_games_folder(app: tauri::AppHandle) -> Result<(), String> {
    let folder = games_directory(&app)?;
    #[cfg(target_os = "windows")]
    let mut command = { let mut cmd = Command::new("explorer.exe"); cmd.arg(&folder); cmd };
    #[cfg(target_os = "macos")]
    let mut command = { let mut cmd = Command::new("open"); cmd.arg(&folder); cmd };
    #[cfg(all(not(target_os = "windows"), not(target_os = "macos")))]
    let mut command = { let mut cmd = Command::new("xdg-open"); cmd.arg(&folder); cmd };
    command.spawn().map_err(|e| format!("Could not open games folder: {e}"))?;
    Ok(())
}

#[tauri::command]
fn dock_info(app: tauri::AppHandle) -> Result<DockInfo, String> {
    let dir = games_directory(&app)?;
    Ok(DockInfo {
        version: DOCK_VERSION,
        games_dir: dir.to_string_lossy().into_owned(),
        os: std::env::consts::OS,
    })
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![list_games, launch_game, open_games_folder, dock_info])
        .run(tauri::generate_context!())
        .expect("error while running Game Dock");
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn ids_are_safe() {
        assert!(valid_id("broadside"));
        assert!(valid_id("game-24"));
        for id in ["", ".", "../other", "Game", "-bad", "bad-", "bad--id", "game\\evil"] {
            assert!(!valid_id(id), "{id}");
        }
    }
    #[test]
    fn executable_paths_are_basenames() {
        assert!(valid_executable("Broadside.exe"));
        assert!(valid_executable("Ship Game_2.EXE"));
        for file in ["", "../run.exe", "C:\\hack.exe", "run.bat", ".exe", "ship.exe/other", "ship.exe && del"] {
            assert!(!valid_executable(file), "{file}");
        }
    }
}
