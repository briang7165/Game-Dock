import { invoke, isTauri } from '@tauri-apps/api/core';
import type { DockInfo, GameEntry } from './types';

export const nativeAvailable = isTauri();

export const listGames = async (): Promise<GameEntry[]> =>
  nativeAvailable ? invoke<GameEntry[]>('list_games') : [];

export const getDockInfo = async (): Promise<DockInfo | null> =>
  nativeAvailable ? invoke<DockInfo>('dock_info') : null;

export const openGamesFolder = async (): Promise<void> => {
  if (!nativeAvailable) throw new Error('Opening local folders requires the desktop application.');
  await invoke('open_games_folder');
};

export const launchGame = async (id: string): Promise<void> => {
  if (!nativeAvailable) throw new Error('Game launching requires the desktop application.');
  await invoke('launch_game', { id });
};
