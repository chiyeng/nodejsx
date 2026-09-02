#!/usr/bin/env bash
# Keep-alive supervisor: keeps the Node service running and
# restarts it every 20 minutes so the container slot stays "fresh".
set -u

PORT="${PORT:-12000}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${PID_FILE:-/tmp/nodejsx.pid}"
LOG_FILE="${LOG_FILE:-/tmp/nodejsx.log}"
RESTART_EVERY="${RESTART_EVERY:-1200}" # 20 minutes
HEARTBEAT_EVERY="${HEARTBEAT_EVERY:-300}" # keep runtime from idle-recycling

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

is_running() {
  if [ ! -f "$PID_FILE" ]; then return 1; fi
  local pid="$(cat "$PID_FILE" 2>/dev/null)"
  [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null
}

start_project() {
  log "starting project (PORT=${PORT})..."
  cd "$PROJECT_DIR"
  export PORT
  nohup node index.js >"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  sleep 2
  if is_running; then
    local ipid="$(cat "$PID_FILE")"
    log "project running (pid=${ipid}, port=${PORT})"
  else
    log "WARN: project failed to start"
  fi
}

stop_project() {
  if [ ! -f "$PID_FILE" ]; then return 0; fi
  local pid="$(cat "$PID_FILE" 2>/dev/null)"
  if [ -n "${pid:-}" ]; then
    kill "$pid" 2>/dev/null
    for _ in 1 2 3 4 5; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    kill -9 "$pid" 2>/dev/null
  fi
  rm -f "$PID_FILE"
}

heartbeat() {
  curl -fsS -m 5 -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null \
    && log "heartbeat ok (port ${PORT})" \
    || log "heartbeat failed (port ${PORT})"
}

log "keepalive supervisor started (pid=$$, restart every ${RESTART_EVERY}s)"
start_project

last_restart="$(date +%s)"
last_beat="$(date +%s)"

while true; do
  now="$(date +%s)"
  if [ $((now - last_restart)) -ge "$RESTART_EVERY" ]; then
    log "scheduled restart every ${RESTART_EVERY}s - restarting project"
    stop_project
    start_project
    last_restart="$(date +%s)"
    heartbeat
  elif ! is_running; then
    log "project died - respawning"
    start_project
    last_restart="$(date +%s)"
  elif [ $((now - last_beat)) -ge "$HEARTBEAT_EVERY" ]; then
    heartbeat
    last_beat="$(date +%s)"
  fi
  sleep 15
done