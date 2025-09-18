#!/usr/bin/env bash
# build.sh — compila o app de menu (requer Xcode CLI)
set -euo pipefail
xcodebuild -scheme MenuBarTunnels -configuration Release || {
  echo "[WARN] este é um scaffold; abra no Xcode e crie o projeto rapidamente."
}
