#!/usr/bin/env python3
"""Seed a simulator's NightCast data container with a realistic, deterministic library.

Measurement script (pre-built, F-007). It only writes files into the simulator
container; it never touches app source. Release builds ignore the UI-test launch
flags, so this is how the baseline gets a populated library.

  seed_library.py <simulator-udid> [--shows 30] [--episodes 150] [--positions 2000]

Writes Library/Application Support/NightCast/library.json and
Library/Caches/Feeds/<sha256(FeedURL.key)>.json in the same formats the app writes.
"""
import argparse, hashlib, json, os, random, shutil, subprocess, sys
from datetime import datetime, timedelta, timezone

BUNDLE = "com.nightcast.ktv2g3z883"
NOW = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)

def iso(d): return d.strftime("%Y-%m-%dT%H:%M:%SZ")

def key(url):  # FeedURL.key: scheme removed, lowercase host, no fragment
    return url.split("://", 1)[1].rstrip("/")

def build(shows_n, eps_n, pos_n):
    rnd = random.Random(20261017)
    shows, feeds, positions = [], {}, {}
    all_eps = []
    for s in range(shows_n):
        feed_url = f"https://seed{s:02d}.nightcast.invalid/feed.xml"
        show = {"feedURL": feed_url, "directoryID": 100000 + s, "title": f"Seed Show {s:02d}",
                "author": f"Seed Studio {s % 7}", "summary": "A deterministic seed show used for measurement. " * 6,
                "artworkURL": f"https://seed{s:02d}.nightcast.invalid/art.jpg"}
        eps = []
        for n in range(eps_n):
            age_days = n * rnd.choice([1, 2, 3, 7])
            pub = NOW - timedelta(days=age_days, hours=rnd.randint(0, 20))
            eps.append({"id": f"seed{s:02d}-ep{n:04d}", "showFeedURL": feed_url, "showTitle": show["title"],
                        "title": f"Episode {eps_n - n}: a quiet story about number {n}",
                        "published": iso(pub), "duration": rnd.randint(1200, 5400),
                        "audioURL": f"https://seed{s:02d}.nightcast.invalid/ep{n:04d}.mp3",
                        "summary": "Show notes. " * 40})
        shows.append(show); feeds[feed_url] = {"show": show, "episodes": eps}
        all_eps += eps
    for ep in rnd.sample(all_eps, min(pos_n, len(all_eps))):
        d = ep["duration"]; done = rnd.random() < 0.6
        positions[ep["id"]] = {"completed": done, "duration": d, "seconds": float(d if done else rnd.randint(0, d)),
                               "updatedAt": iso(NOW - timedelta(days=rnd.randint(0, 120)))}
    last = feeds[shows[0]["feedURL"]]["episodes"][0]
    lib = {"appearanceVersion": 4, "lastEpisode": last, "positions": positions,
           "subscriptions": shows, "themeID": "midnight"}
    return lib, feeds

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("udid"); ap.add_argument("--shows", type=int, default=30)
    ap.add_argument("--episodes", type=int, default=150); ap.add_argument("--positions", type=int, default=2000)
    a = ap.parse_args()
    root = subprocess.check_output(["xcrun", "simctl", "get_app_container", a.udid, BUNDLE, "data"], text=True).strip()
    lib_dir = os.path.join(root, "Library/Application Support/NightCast")
    feed_dir = os.path.join(root, "Library/Caches/Feeds")
    for d in (lib_dir, feed_dir):
        shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
    lib, feeds = build(a.shows, a.episodes, a.positions)
    with open(os.path.join(lib_dir, "library.json"), "w") as f:
        json.dump(lib, f, sort_keys=True, separators=(",", ":"))
    for url, feed in feeds.items():
        name = hashlib.sha256(key(url).encode()).hexdigest() + ".json"
        with open(os.path.join(feed_dir, name), "w") as f:
            json.dump(feed, f, sort_keys=True, separators=(",", ":"))
    size = lambda p: sum(os.path.getsize(os.path.join(p, x)) for x in os.listdir(p))
    print(f"seeded {a.shows} shows x {a.episodes} episodes, {len(lib['positions'])} positions into {root}")
    print(f"library.json {size(lib_dir)} bytes; feed caches {size(feed_dir)} bytes in {len(feeds)} files")

if __name__ == "__main__":
    main()
