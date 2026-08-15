#!/bin/sh
APPDIR="/usr/share/mechanix/mechanix-browser"
exec "$APPDIR/mechanix_browser" --bundle="$APPDIR" "$@"
