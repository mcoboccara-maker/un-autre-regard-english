#!/usr/bin/env python3
"""
play.py — Pilotage Google Play Console depuis le terminal (API Play Developer v3).

SECURITE : la cle du compte de service N'EST PAS dans le depot. Elle est lue depuis
un fichier hors repo (gitignore de fait car hors arborescence) :
  defaut  : C:\\Users\\mcopc\\.secrets\\play-service-account.json
  surcharge: variable d'env GOOGLE_PLAY_JSON=/chemin/vers/sa.json

Le package est auto-detecte depuis android/app/build.gradle(.kts) (applicationId),
surchargeable avec --package.

Pre-requis : pip install pyjwt cryptography   (urllib = stdlib)

Commandes :
  python tools/play.py status
      -> liste tous les tracks (production/beta/alpha/internal) avec, pour chaque
         release : versionCodes, statut, ciblage pays, rollout.

  python tools/play.py promote --to production [--from internal] [--rollout 1.0]
      -> prend la release au versionCode le plus haut du track --from et la publie
         sur le track --to. rollout 1.0 = 100 % (completed) ; 0.1 = 10 % (staged).
         Commit avec envoi en revue (obligatoire pour production).

  python tools/play.py rollout --fraction 0.5 [--track production]
      -> ajuste le pourcentage de deploiement progressif de la release en cours sur
         --track. --fraction 1.0 finalise le rollout (status completed).

Codes de sortie : 0 = OK, !=0 = erreur (message sur stderr).
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

try:
    import jwt  # pyjwt (RS256 -> necessite cryptography)
except ImportError:
    sys.exit("Dependance manquante : pip install pyjwt cryptography")

DEFAULT_JSON = r"C:\Users\mcopc\.secrets\play-service-account.json"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
TOKEN_URL = "https://oauth2.googleapis.com/token"


def sa_path():
    return os.environ.get("GOOGLE_PLAY_JSON", DEFAULT_JSON)


def detect_package():
    """Lit applicationId depuis android/app/build.gradle(.kts)."""
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for name in ("build.gradle", "build.gradle.kts"):
        p = os.path.join(root, "android", "app", name)
        if os.path.exists(p):
            txt = open(p, encoding="utf-8", errors="ignore").read()
            m = re.search(r'applicationId\s*=?\s*["\']([\w.]+)["\']', txt)
            if m:
                return m.group(1)
    return None


def get_token():
    try:
        sa = json.load(open(sa_path(), encoding="utf-8"))
    except OSError as e:
        sys.exit(f"Cle compte de service introuvable ({sa_path()}) : {e}\n"
                 f"Definir GOOGLE_PLAY_JSON ou deposer le JSON a ce chemin.")
    now = int(time.time())
    assertion = jwt.encode(
        {"iss": sa["client_email"], "scope": SCOPE, "aud": TOKEN_URL,
         "iat": now, "exp": now + 3600},
        sa["private_key"], algorithm="RS256")
    data = urllib.parse.urlencode(
        {"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
         "assertion": assertion}).encode()
    with urllib.request.urlopen(urllib.request.Request(TOKEN_URL, data=data), timeout=30) as r:
        return json.load(r)["access_token"]


def api(tok, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{BASE}/{path}", data=data, method=method,
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="ignore")
        raise SystemExit(f"Erreur API {e.code} sur {method} {path}\n{detail}")


def _fmt_release(r):
    vc = ",".join(str(v) for v in r.get("versionCodes", []) or [])
    ct = r.get("countryTargeting")
    countries = "tous pays" if not ct else "pays:" + ",".join(ct.get("countries", []))
    frac = r.get("userFraction")
    roll = f" rollout={frac}" if frac else ""
    return f"vc={vc:9} status={r.get('status',''):22} {r.get('name',''):12} [{countries}]{roll}"


def cmd_status(tok, pkg):
    eid = api(tok, "POST", f"{pkg}/edits")["id"]
    try:
        tracks = api(tok, "GET", f"{pkg}/edits/{eid}/tracks").get("tracks", [])
        print(f"=== {pkg} ===")
        order = {"production": 0, "beta": 1, "alpha": 2, "internal": 3}
        for t in sorted(tracks, key=lambda x: order.get(x["track"], 9)):
            rels = t.get("releases", [])
            if not rels:
                print(f"  {t['track']:12} (vide)")
            for r in rels:
                print(f"  {t['track']:12} {_fmt_release(r)}")
    finally:
        try:
            api(tok, "DELETE", f"{pkg}/edits/{eid}")
        except SystemExit:
            pass


def cmd_promote(tok, pkg, src, dst, rollout):
    eid = api(tok, "POST", f"{pkg}/edits")["id"]
    src_track = api(tok, "GET", f"{pkg}/edits/{eid}/tracks/{src}")
    rels = src_track.get("releases", [])
    if not rels:
        raise SystemExit(f"Aucune release sur le track '{src}', rien a promouvoir.")
    best = max(rels, key=lambda r: max(r.get("versionCodes", [0]) or [0]))
    vcs = best.get("versionCodes", [])
    release = {"versionCodes": vcs, "name": best.get("name", "")}
    if best.get("releaseNotes"):
        release["releaseNotes"] = best["releaseNotes"]
    if rollout >= 1.0:
        release["status"] = "completed"
    else:
        release["status"] = "inProgress"
        release["userFraction"] = rollout
    api(tok, "PUT", f"{pkg}/edits/{eid}/tracks/{dst}",
        {"track": dst, "releases": [release]})
    api(tok, "POST", f"{pkg}/edits/{eid}:commit")
    pct = "100%" if rollout >= 1.0 else f"{rollout*100:.0f}%"
    print(f"OK : {pkg} — versionCode {vcs} promu {src} -> {dst} ({pct}). Envoye en revue Google.")


def cmd_rollout(tok, pkg, track, fraction):
    eid = api(tok, "POST", f"{pkg}/edits")["id"]
    cur = api(tok, "GET", f"{pkg}/edits/{eid}/tracks/{track}")
    rels = cur.get("releases", [])
    if not rels:
        raise SystemExit(f"Aucune release en cours sur '{track}'.")
    rel = rels[0]
    if fraction >= 1.0:
        rel["status"] = "completed"
        rel.pop("userFraction", None)
    else:
        rel["status"] = "inProgress"
        rel["userFraction"] = fraction
    api(tok, "PUT", f"{pkg}/edits/{eid}/tracks/{track}", {"track": track, "releases": [rel]})
    api(tok, "POST", f"{pkg}/edits/{eid}:commit")
    pct = "100% (finalise)" if fraction >= 1.0 else f"{fraction*100:.0f}%"
    print(f"OK : {pkg} — rollout {track} -> {pct}.")


def main():
    ap = argparse.ArgumentParser(description="Pilotage Google Play (API v3).")
    ap.add_argument("--package", help="applicationId (auto-detecte sinon).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status", help="Etat de tous les tracks.")
    p = sub.add_parser("promote", help="Promouvoir une release d'un track a un autre.")
    p.add_argument("--to", required=True, choices=["production", "beta", "alpha", "internal"])
    p.add_argument("--from", dest="src", default="internal",
                   choices=["production", "beta", "alpha", "internal"])
    p.add_argument("--rollout", type=float, default=1.0, help="Fraction 0-1 (defaut 1.0 = 100 pourcent).")
    r = sub.add_parser("rollout", help="Ajuster le rollout progressif d'un track.")
    r.add_argument("--track", default="production", choices=["production", "beta", "alpha", "internal"])
    r.add_argument("--fraction", type=float, required=True, help="Fraction 0-1 (1.0 = finalise).")
    args = ap.parse_args()

    pkg = args.package or detect_package()
    if not pkg:
        sys.exit("Package introuvable : preciser --package com.exemple.app")

    tok = get_token()
    if args.cmd == "status":
        cmd_status(tok, pkg)
    elif args.cmd == "promote":
        cmd_promote(tok, pkg, args.src, args.to, args.rollout)
    elif args.cmd == "rollout":
        cmd_rollout(tok, pkg, args.track, args.fraction)


if __name__ == "__main__":
    main()
