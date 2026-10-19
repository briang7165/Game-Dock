export interface GameEntry {
  id: string;
  name: string;
  version: string;
  genre: string | null;
  description: string | null;
  executable: string;
  ready: boolean;
}

export interface DockInfo {
  version: string;
  games_dir: string;
  os: string;
}
