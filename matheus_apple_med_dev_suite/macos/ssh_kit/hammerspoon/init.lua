-- ~/.hammerspoon/init.lua — app-aware SSH tunnels
-- Requires Hammerspoon (brew install --cask hammerspoon) and ssh-tunnel at ~/.local/bin/ssh-tunnel

local watcher = require("hs.application.watcher")
local task = require("hs.task")
local log = hs.logger.new("ssh-tunnel", "info")

-- map apps to tunnel specs
local MAP = {
  ["Visual Studio Code"] = {
    { name="db", host="clinic-vm", lport="5432", rhost="127.0.0.1", rport="5432" },
  },
  ["TablePlus"] = {
    { name="db", host="clinic-vm", lport="5432", rhost="127.0.0.1", rport="5432" },
  }
}

local RUNNING = {}

local function startTunnel(spec)
  local key = spec.name .. ":" .. spec.host .. ":" .. spec.lport
  if RUNNING[key] then return end
  local env = {
    "HOST="..spec.host, "LPORT="..spec.lport, "RHOST="..spec.rhost, "RPORT="..spec.rport,
    "IDENT="..(spec.ident or os.getenv("HOME").."/.ssh/id_ed25519")
  }
  local cmd = "/bin/bash"
  local args = { "-lc", "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin ~/.local/bin/ssh-tunnel" }
  local t = task.new(cmd, function(exitCode, stdOut, stdErr) RUNNING[key]=nil log.i("tunnel exit "..tostring(exitCode)) end, args)
  t:setEnvironment(env)
  RUNNING[key] = t
  t:start()
  log.i("start tunnel "..key)
end

local function stopTunnel(spec)
  local key = spec.name .. ":" .. spec.host .. ":" .. spec.lport
  local t = RUNNING[key]
  if t then t:terminate(); RUNNING[key]=nil; log.i("stop tunnel "..key) end
end

local function appsChanged(name, event, app)
  if not MAP[name] then return end
  if event == watcher.activated then
    for _, spec in ipairs(MAP[name]) do startTunnel(spec) end
  elseif event == watcher.terminated then
    for _, spec in ipairs(MAP[name]) do stopTunnel(spec) end
  end
end

appWatcher = watcher.new(appsChanged)
appWatcher:start()
hs.alert.show("Hammerspoon SSH tunnels loaded")
