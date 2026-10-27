---
id: 0021
title: Told the user to run `! firebase login`, which cannot work in this environment
area: workflow
severity: minor
status: encoded
---

**What happened:** the user was asked to sign in with `! firebase login`; the CLI refused ("Cannot run login in non-interactive mode"). The Firebase MCP was already signed in the whole time. A second blocker appeared later: `firebase_create_project` failed because the account's project quota was full.
**Root cause:** the instructions assumed an interactive terminal and never checked the login state or the quota first.
**Rule:** check state with the tool before asking the user for anything (`firebase_login` with no arguments reports the account; `firebase_list_projects` shows the quota situation); if a login is needed use the MCP flow, and when a create is refused offer an existing shared project instead of retrying.
**Encoded in:** `skills/monetization/SKILL.md` (Firebase steps), `docs/decisions/0015-ads-and-analytics.md` addenda
