import { useEffect, useMemo, useState } from 'react';
import {
  Anchor, ArrowRight, CheckCircle2, Compass, FolderOpen, Gamepad2, HardDrive,
  Info, Library, Play, RefreshCw, Search, Settings2, ShieldCheck,
  ShipWheel, Sparkles, X,
} from 'lucide-react';
import { getDockInfo, launchGame, listGames, nativeAvailable, openGamesFolder } from './native';
import type { DockInfo, GameEntry } from './types';

type Page = 'home' | 'library' | 'settings';
type Filter = 'all' | 'installed' | 'planned';

function PirateArt() {
  return <div className="ship-illustration" aria-hidden="true">
    <div className="moon"/><div className="sea"/>
    <div className="boat-mast"/><div className="boat-sail main-sail"/><div className="boat-sail fore-sail"/>
    <div className="boat-flag"/><div className="boat-hull"/>
    <div className="wave first"/><div className="wave second"/>
  </div>;
}

export default function App() {
  const [page, setPage] = useState<Page>('home');
  const [filter, setFilter] = useState<Filter>('all');
  const [query, setQuery] = useState('');
  const [games, setGames] = useState<GameEntry[]>([]);
  const [info, setInfo] = useState<DockInfo | null>(null);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  async function refresh() {
    setBusy(true);
    try {
      const [installed, details] = await Promise.all([listGames(), getDockInfo()]);
      setGames(installed);
      setInfo(details);
    } catch (err) {
      setNotice('Could not read library: ' + String(err));
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => { void refresh(); }, []);

  const visible = useMemo(() => games.filter(g =>
    filter !== 'planned' &&
    (g.name + ' ' + (g.genre ?? '')).toLowerCase().includes(query.toLowerCase().trim())
  ), [games, filter, query]);

  const showBroadside = filter !== 'installed' && !games.some(g => g.id === 'broadside') &&
    ('broadside naval arcade pirate game').includes(query.toLowerCase().trim());

  async function play(game: GameEntry) {
    try {
      await launchGame(game.id);
      setNotice('Launched ' + game.name);
    } catch (err) {
      setNotice('Launch failed: ' + String(err));
    }
  }

  async function openFolder() {
    try { await openGamesFolder(); }
    catch (err) { setNotice(String(err)); }
  }

  return <div className="shell">
    <aside className="sidebar">
      <button className="brand" onClick={() => setPage('home')}>
        <span className="brand-icon"><ShipWheel size={28}/></span>
        <span><strong>GAME DOCK</strong><small>PERSONAL ARCADE</small></span>
      </button>
      <p className="nav-label">MENU</p>
      <nav className="nav-items">
        <button className={page === 'home' ? 'selected' : ''} onClick={() => setPage('home')}><Compass size={19}/> Overview</button>
        <button className={page === 'library' ? 'selected' : ''} onClick={() => setPage('library')}><Library size={19}/> My Library <span className="number">{games.length}</span></button>
        <button className={page === 'settings' ? 'selected' : ''} onClick={() => setPage('settings')}><Settings2 size={19}/> Settings</button>
      </nav>
      <div className="sidebar-bottom">
        <div className="side-message"><Sparkles size={20}/><strong>Made for small adventures</strong><p>Your games live on your computer. No store or subscription.</p></div>
        <div className="local-tag"><span className="pulse"/> LOCAL MODE <span>V0.1</span></div>
      </div>
    </aside>

    <main className="main">
      <header className="topbar">
        <div className="breadcrumbs">GAME DOCK <span>›</span> {page === 'home' ? 'Overview' : page === 'library' ? 'My Library' : 'Settings'}</div>
        <div className="top-actions">
          <span className="mode"><span className="pulse"/>{nativeAvailable ? 'Desktop app' : 'Browser preview'}</span>
          <button className="icon-button" title="Refresh games" aria-label="Refresh games" onClick={() => void refresh()}><RefreshCw size={17} className={busy ? 'spinning' : ''}/></button>
          <span className="avatar">GD</span>
        </div>
      </header>
      <div className="content">
        {page === 'home' && <>
          <div className="page-heading"><div><span className="eyebrow">YOUR PERSONAL ARCADE</span><h1>Welcome aboard<span className="accent">.</span></h1><p>A home for little games and big ideas.</p></div><button className="button-outline" onClick={() => setPage('library')}><Library size={17}/> View library</button></div>
          <section className="hero">
            <div className="hero-info">
              <div className="hero-label"><Anchor size={15}/> FIRST GAME ON THE HORIZON</div>
              <h2>Broadside</h2>
              <p>Build your pirate warship. Master cannon fire, outmaneuver rivals, and take on stronger fleets with every encounter.</p>
              <div className="hero-bottom"><span className="planned"><span/> In development</span><button onClick={() => {setPage('library');setFilter('planned');}}>View project <ArrowRight size={17}/></button></div>
            </div>
            <PirateArt/>
          </section>
          <div className="section-heading"><h3>At a glance</h3><p>Your private local library</p></div>
          <div className="stats">
            <div className="stat"><Gamepad2 className="stat-icon" size={23}/><strong>{games.length}</strong><span>Installed games</span></div>
            <div className="stat"><CheckCircle2 className="stat-icon green" size={23}/><strong>Local</strong><span>Offline play</span></div>
            <div className="stat"><ShipWheel className="stat-icon gold" size={23}/><strong>01</strong><span>Planned game</span></div>
          </div>
          <div className="info-note"><ShieldCheck size={19}/> Game Dock does not require an account or network connection to launch locally installed games.</div>
        </>}
        {page === 'library' && <>
          <div className="page-heading"><div><span className="eyebrow">COLLECTION</span><h1>My Library<span className="accent">.</span></h1><p>{games.length} installed {games.length === 1 ? 'game' : 'games'}</p></div><button className="button-outline" onClick={() => void openFolder()}><FolderOpen size={17}/> Open games folder</button></div>
          <div className="library-tools">
            <div className="filter-tabs">{(['all', 'installed', 'planned'] as Filter[]).map(k =>
              <button key={k} className={filter === k ? 'active' : ''} onClick={() => setFilter(k)}>{k === 'all' ? 'All games' : k === 'installed' ? 'Installed' : 'Coming soon'}</button>
            )}</div>
            <label className="search"><Search size={17}/><input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search library" aria-label="Search games"/></label>
          </div>
          <div className="game-grid">
            {visible.map(g => <article className="game-card" key={g.id}>
              <div className="game-art"><ShipWheel size={52}/><span>LOCAL GAME</span></div>
              <div className="game-description"><span className="category">{g.genre ?? 'Game'} · v{g.version}</span><h3>{g.name}</h3><p>{g.description ?? 'Standalone desktop game'}</p><button className="button-primary" disabled={!g.ready} onClick={() => void play(g)}><Play size={15} fill="currentColor"/>{g.ready ? 'Play game' : 'Executable missing'}</button></div>
            </article>)}
            {showBroadside && <article className="game-card">
              <div className="game-art planned-art"><ShipWheel size={64}/><span>FUTURE GAME</span></div>
              <div className="game-description"><span className="category">NAVAL ARCADE · PLANNED</span><h3>Broadside</h3><p>One ship, endless battles, bigger guns, better sails, and smarter enemies.</p><button className="button-primary" disabled>Not yet available</button></div>
            </article>}
            {visible.length === 0 && !showBroadside && <div className="empty"><Search size={29}/><h3>No games found</h3><p>Try another search or add a game with a valid manifest.</p></div>}
          </div>
          <div className="help"><FolderOpen size={22}/><div><strong>How do I add a game?</strong><p>Open the games folder. Add an executable and a matching <code>game.json</code> in their own game-ID subfolder. Refresh when finished.</p></div><button onClick={() => void openFolder()}>Open folder <ArrowRight size={16}/></button></div>
        </>}
        {page === 'settings' && <>
          <div className="page-heading"><div><span className="eyebrow">PREFERENCES</span><h1>Settings<span className="accent">.</span></h1><p>Manage your local game library.</p></div></div>
          <section className="settings-card"><HardDrive size={27}/><div><h3>Game installations</h3><p>Game Dock discovers standalone games through local manifests.</p><span className="path-label">CURRENT LIBRARY PATH</span><code className="path">{info?.games_dir ?? (nativeAvailable ? 'Loading…' : 'Available in desktop mode')}</code><button className="button-outline" onClick={() => void openFolder()}><FolderOpen size={17}/> Open games folder</button></div></section>
          <section className="settings-card"><Info size={27}/><div><h3>About Game Dock</h3><p>A local-first desktop launcher built with Tauri, Rust, React, and TypeScript.</p><dl><dt>Version</dt><dd>{info?.version ?? '0.1.0'}</dd><dt>Platform</dt><dd>{info?.os ?? 'Browser preview'}</dd><dt>Downloads / updates</dt><dd>Not implemented yet</dd></dl></div></section>
        </>}
      </div>
      <footer>GAME DOCK <span>•</span> MADE FOR THE LOVE OF GAMES <span className="footer-right">V0.1 SOURCE PREVIEW</span></footer>
    </main>
    {notice && <div className="toast" role="status">{notice}<button aria-label="Dismiss message" onClick={() => setNotice(null)}><X size={18}/></button></div>}
  </div>;
}
