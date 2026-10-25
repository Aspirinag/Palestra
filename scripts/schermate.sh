#!/bin/bash
# Fa le schermate dell'app nel simulatore iPhone, in modalità chiara e scura, con i dati di prova (-demo).
# Uso: scripts/schermate.sh <App.app> <bundle id> "<scheda[:vista]> ..."
set -euo pipefail
APP=$1; BUNDLE=$2; SCHEDE=$3

# iPhone (preferibilmente Pro) con la versione di iOS più recente installata
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
d = json.load(sys.stdin)["devices"]
runtime = sorted((r for r in d if "iOS" in r and any(x["name"].startswith("iPhone") for x in d[r])),
                 key=lambda r: [int(n) for n in r.split("iOS-")[-1].split("-")])[-1]
iphone = [x for x in d[runtime] if x["name"].startswith("iPhone")]
pro = [x for x in iphone if x["name"].endswith(" Pro")]
print((pro or iphone)[0]["udid"])
')
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$APP"
mkdir -p schermate
for aspetto in light dark; do
  xcrun simctl ui "$UDID" appearance $aspetto
  for s in $SCHEDE; do
    scheda=${s%%:*}; vista=${s#*:}
    args=(-demo -tab "$scheda")
    [ "$vista" != "$s" ] && args+=(-vista "$vista")
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" "${args[@]}" > /dev/null
    sleep 5
    nome="schermate/$aspetto-${s/:/-}.png"
    xcrun simctl io "$UDID" screenshot "$nome" > /dev/null
    sips -Z 1100 "$nome" > /dev/null
  done
done
ls schermate
