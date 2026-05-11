#!/bin/zsh
# Installer for the "Convert TS to MP4" and "Convert TS to MKV" Quick Actions.
# Builds both .workflow bundles in ~/Library/Services and verifies prerequisites.

set -euo pipefail

SERVICES_DIR="${HOME}/Library/Services"

print_step()  { printf "\033[1;34m==>\033[0m %s\n" "$1"; }
print_ok()    { printf "\033[1;32m  ✓\033[0m %s\n" "$1"; }
print_warn()  { printf "\033[1;33m  !\033[0m %s\n" "$1"; }
print_error() { printf "\033[1;31m  ✗\033[0m %s\n" "$1" >&2; }

# --- 1. ffmpeg check -------------------------------------------------------

print_step "Checking for ffmpeg"
if FFMPEG_PATH="$(command -v ffmpeg)"; then
  print_ok "Found ffmpeg at ${FFMPEG_PATH}"
else
  print_warn "ffmpeg not found on PATH"
  if command -v brew >/dev/null 2>&1; then
    printf "    Install ffmpeg with Homebrew now? [y/N] "
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      brew install ffmpeg
      FFMPEG_PATH="$(command -v ffmpeg)"
      print_ok "Installed ffmpeg at ${FFMPEG_PATH}"
    else
      print_error "Aborted. Install ffmpeg manually and re-run this script."
      exit 1
    fi
  else
    print_error "Homebrew not found. Install Homebrew (https://brew.sh) or ffmpeg manually, then re-run."
    exit 1
  fi
fi

# --- 2. Build helper -------------------------------------------------------

# build_workflow <service-name> <shell-script>
build_workflow() {
  local service_name="$1"
  local shell_script="$2"
  local workflow_dir="${SERVICES_DIR}/${service_name}.workflow"
  local contents_dir="${workflow_dir}/Contents"

  if [[ -d "$workflow_dir" ]]; then
    print_step "Removing existing ${service_name}.workflow"
    rm -rf "$workflow_dir"
  fi

  print_step "Creating ${service_name}.workflow"
  mkdir -p "$contents_dir"

  cat > "${contents_dir}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>${service_name}</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSApplicationIdentifier</key>
                <string>com.apple.finder</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.mpeg-2-transport-stream</string>
                <string>public.item</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

  local wflow_tmp
  wflow_tmp="$(mktemp)"
  cat > "$wflow_tmp" <<'WFLOW'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>*</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <dict/>
                    <key>CheckedForUserDefaultShell</key>
                    <dict/>
                    <key>inputMethod</key>
                    <dict/>
                    <key>shell</key>
                    <dict/>
                    <key>source</key>
                    <dict/>
                </dict>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>__SCRIPT_PLACEHOLDER__</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/zsh</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
                <key>CanShowSelectedItemsWhenRun</key>
                <false/>
                <key>CanShowWhenRun</key>
                <true/>
                <key>Category</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>Class Name</key>
                <string>RunShellScriptAction</string>
                <key>InputUUID</key>
                <string>11111111-1111-1111-1111-111111111111</string>
                <key>Keywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                    <string>Command</string>
                    <string>Run</string>
                    <string>Unix</string>
                </array>
                <key>OutputUUID</key>
                <string>22222222-2222-2222-2222-222222222222</string>
                <key>UUID</key>
                <string>33333333-3333-3333-3333-333333333333</string>
                <key>UnlocalizedApplications</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>arguments</key>
                <dict/>
                <key>isViewVisible</key>
                <integer>1</integer>
                <key>location</key>
                <string>309.500000:316.000000</string>
                <key>nibPath</key>
                <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
            </dict>
            <key>isViewVisible</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>serviceApplicationBundleID</key>
        <string>com.apple.finder</string>
        <key>serviceApplicationPath</key>
        <string>/System/Library/CoreServices/Finder.app</string>
        <key>serviceInputTypeIdentifier</key>
        <string>com.apple.Automator.fileSystemObject</string>
        <key>serviceOutputTypeIdentifier</key>
        <string>com.apple.Automator.nothing</string>
        <key>serviceProcessesInput</key>
        <integer>0</integer>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
WFLOW

  /usr/bin/env python3 - "$wflow_tmp" "${contents_dir}/document.wflow" <<'PY' "$shell_script"
import sys, html
src, dst = sys.argv[1], sys.argv[2]
script = sys.argv[3]
with open(src) as f:
    body = f.read()
body = body.replace("__SCRIPT_PLACEHOLDER__", html.escape(script, quote=False))
with open(dst, "w") as f:
    f.write(body)
PY

  rm -f "$wflow_tmp"
  print_ok "Bundle written to ${workflow_dir}"
}

# --- 3. Shell scripts for each Quick Action --------------------------------

# MP4 variant. `-tag:v hvc1` makes HEVC streams (e.g. HDZero DVR) play in
# QuickTime/Finder/iMovie — without it, the stream is muxed as `hev1` and
# QuickTime renders audio only.
read -r -d '' MP4_SCRIPT <<'SCRIPT' || true
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"Convert TS to MP4\""
}

count_total=0
count_ok=0
count_skip=0
count_fail=0

for f in "$@"; do
  count_total=$((count_total + 1))
  case "$f" in
    *.ts|*.TS) ;;
    *)
      count_skip=$((count_skip + 1))
      continue
      ;;
  esac

  out="${f%.*}.mp4"
  # Only tag as hvc1 if the source video is HEVC. Applying -tag:v hvc1 to an
  # H.264 stream (e.g. HDZero) makes ffmpeg refuse to write the mp4 header.
  vcodec="$(/usr/bin/env ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$f" 2>/dev/null)"
  tag_args=()
  if [ "$vcodec" = "hevc" ]; then
    tag_args=(-tag:v hvc1)
  fi
  if /usr/bin/env ffmpeg -y -i "$f" -map 0:v -map "0:a?" -c copy "${tag_args[@]}" "$out" </dev/null >/dev/null 2>&1; then
    count_ok=$((count_ok + 1))
  else
    count_fail=$((count_fail + 1))
  fi
done

if [ "$count_total" -eq 1 ] && [ "$count_ok" -eq 1 ]; then
  notify "Converted $(basename "$1") → $(basename "${1%.*}").mp4"
elif [ "$count_ok" -gt 0 ] && [ "$count_fail" -eq 0 ]; then
  notify "Converted ${count_ok} file(s) successfully"
elif [ "$count_fail" -gt 0 ]; then
  notify "Done — ${count_ok} succeeded, ${count_fail} failed"
elif [ "$count_skip" -eq "$count_total" ]; then
  notify "No .ts files in selection"
fi
SCRIPT

# MKV variant. Matroska accepts any codec, so the remux works on any .ts
# source without codec tagging. Plays in VLC / IINA (not native QuickTime).
read -r -d '' MKV_SCRIPT <<'SCRIPT' || true
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"Convert TS to MKV\""
}

count_total=0
count_ok=0
count_skip=0
count_fail=0

for f in "$@"; do
  count_total=$((count_total + 1))
  case "$f" in
    *.ts|*.TS) ;;
    *)
      count_skip=$((count_skip + 1))
      continue
      ;;
  esac

  out="${f%.*}.mkv"
  if /usr/bin/env ffmpeg -y -i "$f" -map 0:v -map "0:a?" -c copy "$out" </dev/null >/dev/null 2>&1; then
    count_ok=$((count_ok + 1))
  else
    count_fail=$((count_fail + 1))
  fi
done

if [ "$count_total" -eq 1 ] && [ "$count_ok" -eq 1 ]; then
  notify "Converted $(basename "$1") → $(basename "${1%.*}").mkv"
elif [ "$count_ok" -gt 0 ] && [ "$count_fail" -eq 0 ]; then
  notify "Converted ${count_ok} file(s) successfully"
elif [ "$count_fail" -gt 0 ]; then
  notify "Done — ${count_ok} succeeded, ${count_fail} failed"
elif [ "$count_skip" -eq "$count_total" ]; then
  notify "No .ts files in selection"
fi
SCRIPT

# --- 4. Build both bundles -------------------------------------------------

build_workflow "Convert TS to MP4" "$MP4_SCRIPT"
build_workflow "Convert TS to MKV" "$MKV_SCRIPT"

# --- 5. Refresh the Services menu -----------------------------------------

print_step "Refreshing Finder services"
/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true

print_ok "Done. Right-click a .ts file in Finder → Quick Actions → Convert TS to MP4 / MKV"
print_warn "If the menu items don't appear immediately, log out and back in (or just relaunch Finder: \`killall Finder\`)."
