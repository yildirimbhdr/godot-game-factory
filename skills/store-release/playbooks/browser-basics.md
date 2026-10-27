# Driving the store consoles with Claude in Chrome (hard-won rules)

- Ask first, then use the user's already signed-in Chrome session. Open your own tab, close it when done. `file://` pages are blocked: serve local files with `python3 -m http.server --bind 127.0.0.1` if you must look at one.
- **Several Google accounts**: Google consoles use `/u/<n>/` in the URL. The signed-in accounts are separate indexes (`u/0`, `u/1`, `u/2` ...). Open `https://play.google.com/console/u/<n>/developers` for each and read the e-mail on the account chooser to find the right one. Never click into an account the user did not name.
- **Typing**: React forms in these consoles ignore `form_input`. Click the field with a real click, then `type`. To replace existing text: click, `key cmd+a`, `type`.
- **Native `<select>`**: click it, type the option text, press Return. `form_input` selects do not register.
- Long text (a 1,200-character description) may make `type` report a timeout; the text usually still arrived. Look at the field before retyping.
- `computer wait` is capped at 10 s per call.
- **Uploads**: use the `file_upload` tool with the `<input type=file>` ref from `find`; never click the visible Upload button (a native picker cannot be driven). Files under the user's project folder are accepted, 10 MB per call.
- **Uploaded thumbnails stay as a grey cloud placeholder for 30-60+ s.** Wait; do not delete them (that cost two needless re-uploads). Multi-file uploads are fine; only re-upload what is still missing after a full minute.
- Reordering uploaded screenshots: drag the tile (`left_click_drag`) to the target slot; verify with a zoom.
- Terms, declarations, payments, tax, identity and every final submit/publish click need an explicit yes in chat first (see the skill's table).
- **Popup lists scroll under the pointer**: refs of items in an open language menu go stale. Scroll the list with the wheel, screenshot, click by coordinates (lesson 0049). A `"Leave site?"` dialog blocks navigation; `navigate` with `force: true` discards unsaved changes, so use it only for changes you made by mistake.
