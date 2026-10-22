// Shared demo content and drawing helpers for the refresh mockups.
// Content is the same six real shows the app's -demo launch seeds.
const ART = {
  nmh: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts221/v4/87/f2/26/87f226c9-77ac-d4fe-6b98-4da2345de5c0/mza_5833691041544808336.jpg/600x600bb.jpg",
  radiolab: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/2b/b2/4d/2bb24d28-f3bb-916f-6bf3-9e125ba5219b/mza_4476298389845914795.jpg/600x600bb.jpg",
  invisible: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/79/d0/35/79d035ea-9043-b43e-7380-33cd47bd968b/mza_2606971010425550919.jpg/600x600bb.jpg",
  swm: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts112/v4/a6/2d/96/a62d9642-5efe-e042-3673-e242aa1346fd/mza_13039729790115515983.jpg/600x600bb.jpg",
  moth: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts221/v4/16/39/63/1639632d-7ad2-d87b-d4f7-d0ec95eff386/mza_8915289722686017414.jpg/600x600bb.jpg",
  carlin: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts115/v4/49/b7/eb/49b7eb32-8f08-6fac-aadb-2f002131fe5f/mza_15196161972010256532.jpg/600x600bb.jpg",
};
const SHOWS = [
  { id: "nmh", title: "Nothing much happens", full: "Nothing much happens: bedtime stories to help you sleep", by: "Wellness Loud", isNew: true },
  { id: "radiolab", title: "Radiolab", by: "WNYC Studios" },
  { id: "invisible", title: "99% Invisible", by: "Roman Mars" },
  { id: "swm", title: "Sleep With Me", by: "Silver Sleeper Productions", isNew: true },
  { id: "moth", title: "The Moth", by: "The Moth" },
  { id: "carlin", title: "Hardcore History", by: "Dan Carlin" },
];
const EPISODES = [
  { t: "The Moon and the Maker’s Mark", d: "Oct 18", len: "1 hr 2 min", state: "new" },
  { t: "Crows and Candles (Encore)", d: "Oct 14", len: "39 min", state: "progress", left: "22 min left", pct: 0.44 },
  { t: "Slightly More Happens: October Oracles", d: "Oct 11", len: "2 hr 10 min", state: "played" },
  { t: "The Corn Maze or The Say Yes Club", d: "Oct 7", len: "41 min", state: "played" },
  { t: "Paper Flowers", d: "Oct 4", len: "44 min", state: "played" },
  { t: "The Night Market", d: "Sep 30", len: "47 min", state: "played" },
];
const NOW = { show: "Radiolab", title: "The Smell of Hell", art: "radiolab", elapsed: "14:22", remaining: "−33:33", pct: 0.30 };
const SHOW_DESC = "Can’t sleep? You’re not alone, and there’s help. Nothing Much Happens is a bedtime story podcast for grown-ups, read slowly so you drift off.";

const I = {
  play: '<svg viewBox="0 0 24 24"><path d="M7 4.5v15a1 1 0 0 0 1.5.86l12.4-7.5a1 1 0 0 0 0-1.72L8.5 3.64A1 1 0 0 0 7 4.5Z" fill="currentColor"/></svg>',
  pause: '<svg viewBox="0 0 24 24"><rect x="6" y="4" width="4.2" height="16" rx="1.2" fill="currentColor"/><rect x="13.8" y="4" width="4.2" height="16" rx="1.2" fill="currentColor"/></svg>',
  back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>',
  down: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 9l7 7 7-7"/></svg>',
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="10.5" cy="10.5" r="6.5"/><path d="M15.5 15.5L20 20"/></svg>',
  moon: '<svg viewBox="0 0 24 24"><path d="M20.5 14.6A8.5 8.5 0 0 1 9.4 3.5a8.5 8.5 0 1 0 11.1 11.1Z" fill="currentColor"/></svg>',
  r15: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M7.5 11A11 11 0 1 1 5 18"/><path d="M7.5 4.5V11H14"/><text x="16" y="21.5" font-size="9.5" font-weight="700" text-anchor="middle" fill="currentColor" stroke="none" font-family="-apple-system">15</text></svg>',
  f15: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M24.5 11A11 11 0 1 0 27 18"/><path d="M24.5 4.5V11H18"/><text x="16" y="21.5" font-size="9.5" font-weight="700" text-anchor="middle" fill="currentColor" stroke="none" font-family="-apple-system">15</text></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
  sort: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 4v16M4 16l4 4 4-4M16 20V4M12 8l4-4 4 4"/></svg>',
  grid: '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="7" height="7" rx="1.6"/><rect x="13" y="4" width="7" height="7" rx="1.6"/><rect x="4" y="13" width="7" height="7" rx="1.6"/><rect x="13" y="13" width="7" height="7" rx="1.6"/></svg>',
  dots: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/></svg>',
};
// iOS status bar (time, signal, wifi, battery) in currentColor.
function statusBar(time) {
  return `<div class="sb"><span class="sb-time">${time}</span><span class="sb-right">
  <svg width="19" height="12" viewBox="0 0 19 12" fill="currentColor"><rect x="0" y="8" width="3.2" height="4" rx=".8"/><rect x="5" y="5.5" width="3.2" height="6.5" rx=".8"/><rect x="10" y="3" width="3.2" height="9" rx=".8"/><rect x="15" y="0" width="3.2" height="12" rx=".8"/></svg>
  <svg width="17" height="12" viewBox="0 0 17 12" fill="currentColor"><path d="M8.5 2.3c2.4 0 4.6.9 6.2 2.5l1.2-1.2A10.4 10.4 0 0 0 8.5.6 10.4 10.4 0 0 0 1.1 3.6l1.2 1.2A8.7 8.7 0 0 1 8.5 2.3Zm0 3.4c1.5 0 2.9.6 4 1.6l1.2-1.2a7.3 7.3 0 0 0-10.4 0l1.2 1.2c1.1-1 2.5-1.6 4-1.6Zm0 3.4c.6 0 1.2.2 1.6.7L8.5 11.4 6.9 9.8c.4-.5 1-.7 1.6-.7Z"/></svg>
  <svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.5" fill="none" stroke="currentColor" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2" fill="currentColor"/><path d="M25 4.5v4c.8-.3 1.3-1.1 1.3-2s-.5-1.7-1.3-2Z" fill="currentColor" opacity=".45"/></svg>
  </span></div><div class="island"></div>`;
}
function homeBar() { return '<div class="hb"></div>'; }
function art(id, cls = "") { return `<img class="art ${cls}" src="${ART[id]}" alt="">`; }
// Moon phase as SVG. k = illuminated fraction (1 full .. 0 new), waning (lit on the left).
function phase(k, size, lit, dark, ring) {
  const r = 10, rx = Math.abs(1 - 2 * k) * r;
  const sweepT = k > 0.5 ? 1 : 0;
  const path = k >= 0.999 ? `<circle cx="12" cy="12" r="10" fill="${lit}"/>` : k <= 0.001 ? "" :
    `<path d="M12 2 A10 10 0 0 0 12 22 A${rx} 10 0 0 ${sweepT} 12 2 Z" fill="${lit}"/>`;
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" style="flex:none"><circle cx="12" cy="12" r="10" fill="${dark}" ${ring ? `stroke="${ring}" stroke-width="1.2"` : ""}/>${path}</svg>`;
}
