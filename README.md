# Convert TS to MP4 — macOS Quick Action

Right-click any `.ts` file in Finder and remux it to `.mp4` with a single click. No re-encoding, no quality loss, no waiting — just a container swap powered by `ffmpeg`.

```
Finder ▸ right-click  ▸  Quick Actions  ▸  Convert TS to MP4
```

A native macOS notification fires when the conversion finishes. The original `.ts` file is left untouched.

---

## Why

MPEG-TS (`.ts`) is a streaming-friendly container that a lot of editors, players, and upload tools refuse to touch. The video and audio streams inside are usually already H.264 + AAC — exactly what an MP4 wants — so converting is just a matter of repackaging the streams. That takes about a second per gigabyte and is bit-for-bit lossless.

This repo packages that as a one-click Finder Quick Action so you don't have to drop into a terminal every time.

## Requirements

- macOS 11 (Big Sur) or newer
- [`ffmpeg`](https://ffmpeg.org) — the installer will offer to install it via Homebrew if missing

## Install

```sh
git clone https://github.com/smika6/mac-ts-to-mp4-quick-action.git
cd mac-ts-to-mp4-quick-action
./install.sh
```

The installer will:
1. Check that `ffmpeg` is on your `PATH` (offering a `brew install ffmpeg` if not)
2. Build the `Convert TS to MP4.workflow` bundle into `~/Library/Services/`
3. Refresh the macOS Services menu so the Quick Action shows up immediately

If the menu item doesn't appear right away, run `killall Finder` or log out and back in.

## Usage

1. Open Finder and select one or more `.ts` files (multi-select works)
2. Right-click → **Quick Actions** → **Convert TS to MP4**
3. Wait for the notification

Each output lands next to its source: `clip.ts` → `clip.mp4`. Existing `.mp4` files with the same name are overwritten (`ffmpeg -y`). The originals are not deleted.

## How it works

The Quick Action is a single Automator **Run Shell Script** action that runs:

```sh
ffmpeg -y -i input.ts -vcodec copy -acodec copy -map 0:v -map 0:a input.mp4
```

`-vcodec copy -acodec copy` tells `ffmpeg` to pass the existing video and audio streams through untouched — no decode/encode round-trip — so the result is identical in quality to the source and finishes nearly as fast as a file copy.

If your `.ts` file contains streams that aren't natively MP4-compatible (e.g. MPEG-2 video, AC-3 audio), the `copy` mux will fail and you'll get a "failed" notification. In that case you'll need to re-encode — that's outside the scope of this one-click tool.

## Uninstall

```sh
./uninstall.sh
```

Or just delete `~/Library/Services/Convert TS to MP4.workflow` manually.

## Manual setup (if you'd rather build it in Automator yourself)

<details>
<summary>Click to expand</summary>

1. Open **Automator** → **File** → **New** → **Quick Action**
2. Set **Workflow receives current** to `files or folders` **in** `Finder`
3. Drag in a **Run Shell Script** action
4. **Shell:** `/bin/zsh`, **Pass input:** `as arguments`
5. Paste:

   ```sh
   PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
   for f in "$@"; do
     case "$f" in
       *.ts|*.TS)
         ffmpeg -y -i "$f" -vcodec copy -acodec copy -map 0:v -map 0:a "${f%.*}.mp4"
         ;;
     esac
   done
   osascript -e 'display notification "Done" with title "Convert TS to MP4"'
   ```

6. **File** → **Save** → name it `Convert TS to MP4`

</details>

## License

[MIT](LICENSE)
