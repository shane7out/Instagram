#!/usr/bin/env python3
"""Shane (2026-11-26): double-tap the Key Technologies.si logo (top left) on the home page and the blue PIN pad (Treasury) opens.
Adds key-platform/owner-door.js to the home page only (there the logo is a same-page link, so a single tap costs no delay). Idempotent."""
import pathlib
f = pathlib.Path('sites/key-technologies/index.html'); s = f.read_text(encoding='utf-8')
tag = '<script src="key-platform/owner-door.js" defer></script>'
if tag in s: print('unchanged')
else:
    f.write_text(s.replace('</body>', tag + '</body>', 1), encoding='utf-8'); print('added to index.html')
