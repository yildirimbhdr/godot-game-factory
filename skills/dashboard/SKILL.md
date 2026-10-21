---
name: dashboard
description: Show the publisher dashboard - the user's profile (developer name, brand, public contact email, locales, keystore location, hosting site) and every game in the workspace with its ids, store assets, listing, privacy page, builds and release progress. Use when the user asks for a panel, dashboard, overview, "what did I enter", "which info is stored", or the state of their games.
---

# Dashboard and profile

The profile is the user's own publisher data, asked **once** and reused by every game: `~/.game-factory/profile.json`
(`scripts/gf_profile.py show|set`). Keys: developer_name, brand, public_contact_email, default_locales, workspace,
firebase_project, hosting_site, android_keystore, android_keychain_service, website, support_url.

## Rules
- Before asking the user for any of these in a task (store listing, privacy policy, release), read the profile first
  (`python3 scripts/gf_profile.py show`); ask only for what is empty, then save it with `gf_profile.py set`.
- Only a **public** contact email goes into the profile (it is printed into policies and listings). Ask; never reuse the account email unasked.
- Never store passwords or keys in it. The Android upload password lives in the macOS Keychain; the profile only names the keystore file.
- Data stays on the user's machine. The plugin never uploads the profile or the dashboard; every person who installs the plugin gets
  their own profile and their own dashboard, built from their own files. Say this plainly when asked who can see the data.

## Show the dashboard
`python3 scripts/dashboard.py --open` writes `~/.game-factory/dashboard.html` (offline, no network requests, follows light/dark) and opens it.
It lists, per game: bundle id and package, version, AdMob and Firebase ids, Definition of Done result, module and live-id state, store graphics,
listing check, privacy page, builds, git state, and the release progress (`store/status.json` holds the user-confirmed facts: privacy_url,
play_submitted, apple_submitted). After a release step, update `store/status.json` and regenerate.
A private shareable copy as a claude.ai Artifact is possible only if the user asks; it would put these values on claude.ai.
