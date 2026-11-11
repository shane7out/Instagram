#!/bin/bash
# Run on the Mac ONCE (one command). Sets up an automatic weekly backup of your whole database to a folder on your Mac (~/lvr-backups), then makes the first backup now.
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/backup-setup.sh?$(date +%s)" -o /tmp/backup-setup.sh && bash /tmp/backup-setup.sh
# You type your owner email and password HERE in Terminal (they go only to Google to sign in; the password is NOT saved anywhere). What is saved is a renewable
# sign-in token in ~/.lvr/owner-refresh (readable only by you), so the weekly job can read your private areas (leads, CRM) without asking again.
# The backups never leave your Mac. Newest 12 weeks are kept. To stop: launchctl unload ~/Library/LaunchAgents/com.keytech.backup.plist
set +e
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
command -v node >/dev/null 2>&1 || { echo "Node is not installed on this Mac - tell Claude."; exit 1; }
mkdir -p "$HOME/.lvr" "$HOME/lvr-backups"; chmod 700 "$HOME/.lvr"
curl -sL -o "$HOME/.lvr/backup-database.js" "$RAWB/backup-database.js?cb=$(date +%s)"
node --check "$HOME/.lvr/backup-database.js" || { echo "The backup program did not download correctly - nothing changed."; exit 1; }
KEY=$(curl -s "$DB/ownerAuth/apiKey.json" | tr -d '"')
[ -n "$KEY" ] && [ "$KEY" != "null" ] || { echo "Could not read the sign-in key - nothing changed."; exit 1; }
echo "Owner sign-in for the backup (the same email and password you use for the Owner sign-in button)."
read -r -p "Owner email: " EM
read -r -s -p "Owner password (not shown, not saved): " PW; echo
RESP=$(EM="$EM" PW="$PW" KEY="$KEY" node -e '
fetch("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="+encodeURIComponent(process.env.KEY),{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email:process.env.EM,password:process.env.PW,returnSecureToken:true})}).then(r=>r.json()).then(j=>{console.log(j.refreshToken?("OK "+j.refreshToken):("FAIL "+((j.error&&j.error.message)||"?")))}).catch(e=>console.log("FAIL "+e.message))')
unset PW
case "$RESP" in
  OK\ *) printf '%s' "${RESP#OK }" > "$HOME/.lvr/owner-refresh"; chmod 600 "$HOME/.lvr/owner-refresh"; echo "Signed in. Saved a renewable token (not your password).";;
  *) echo "Sign-in did not work ($RESP). Nothing was set up. Check the email and password and try again."; exit 1;;
esac
PLIST="$HOME/Library/LaunchAgents/com.keytech.backup.plist"; mkdir -p "$HOME/Library/LaunchAgents"
NODEBIN=$(command -v node)
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.keytech.backup</string>
  <key>ProgramArguments</key><array><string>$NODEBIN</string><string>$HOME/.lvr/backup-database.js</string></array>
  <key>StartCalendarInterval</key><dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>3</integer><key>Minute</key><integer>10</integer></dict>
  <key>StandardOutPath</key><string>$HOME/.lvr/backup.log</string><key>StandardErrorPath</key><string>$HOME/.lvr/backup.log</string>
</dict></plist>
PL
launchctl unload "$PLIST" >/dev/null 2>&1; launchctl load "$PLIST" && echo "Weekly backup scheduled: every Sunday at 3:10 am (if the Mac is asleep it runs when it wakes)."
echo "Making the first backup now..."
node "$HOME/.lvr/backup-database.js"
echo
echo "Your backups are in: $HOME/lvr-backups"
