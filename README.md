# Convert TS to MP4 / MKV — macOS Quick Actions

Right-click any `.ts` file in Finder and remux it to `.mp4` or `.mkv` with a single click. No re-encoding, no quality loss, no waiting — just a container swap powered by `ffmpeg`.

```
Finder ▸ right-click  ▸  Quick Actions  ▸  Convert TS to MP4
                                       ▸  Convert TS to MKV
```

A native macOS notification fires when the conversion finishes. The original `.ts` file is left untouched.

---

## Which one should I use?

| | **MP4** | **MKV** |
|---|---|---|
| Plays in QuickTime / Finder preview / iMovie | ✅ | ❌ (use VLC / IINA) |
| Works with any codec inside the `.ts` | ⚠️ H.264 + AAC, or HEVC (auto-tagged `hvc1`) | ✅ Always |
| Recommended for | Sharing, editing, AirDrop | Anything exotic, or when MP4 fails |

For HDZero DVR clips (H.264) MP4 works directly. If a source is HEVC, the script auto-applies the `hvc1` codec tag so QuickTime/iMovie still recognize the video. For anything that fails as MP4, use MKV.

## Why a remux (not a re-encode)?

MPEG-TS (`.ts`) is a streaming-friendly container that a lot of editors, players, and upload tools refuse to touch. The video and audio streams inside are already a normal codec (H.264, HEVC, AAC, etc.) — converting is just a matter of repackaging the streams. That takes about a second per gigabyte and is bit-for-bit lossless.

This repo packages that as one-click Finder Quick Actions so you don't have to drop into a terminal every time.

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
2. Build both `Convert TS to MP4.workflow` and `Convert TS to MKV.workflow` into `~/Library/Services/`
3. Refresh the macOS Services menu so the Quick Actions show up immediately

If the menu items don't appear right away, run `killall Finder` or log out and back in.

## Usage

1. Open Finder and select one or more `.ts` files (multi-select works)
2. Right-click → **Quick Actions** → **Convert TS to MP4** *or* **Convert TS to MKV**
3. Wait for the notification

Each output lands next to its source: `clip.ts` → `clip.mp4` / `clip.mkv`. Existing files with the same name are overwritten (`ffmpeg -y`). The originals are not deleted.

## How it works

The Quick Actions are Automator **Run Shell Script** actions. They run, respectively:

```sh
# MP4 — for HEVC sources only, the script also passes -tag:v hvc1
ffmpeg -y -i input.ts -map 0:v -map "0:a?" -c copy [-tag:v hvc1] input.mp4

# MKV
ffmpeg -y -i input.ts -map 0:v -map "0:a?" -c copy              input.mkv
```

`-c copy` tells `ffmpeg` to pass the existing video and audio streams through untouched — no decode/encode round-trip — so the result is identical in quality to the source and finishes nearly as fast as a file copy.

The MP4 script probes the source video codec with `ffprobe`. If it's HEVC it adds `-tag:v hvc1` so Apple's frameworks recognize the stream — without that tag, HEVC-in-MP4 plays audio only in QuickTime / Finder preview / iMovie. For H.264 (e.g. HDZero DVR) no tag is needed, and applying `hvc1` to H.264 would make the mux fail. `-map "0:a?"` makes the audio track optional, since some sources — including HDZero — have no audio.

If a `.ts` file contains streams MP4 can't carry (e.g. some flavors of MPEG-2, AC-3 audio), the MP4 mux will fail and you'll get a "failed" notification — try the MKV action instead.

## Uninstall

```sh
./uninstall.sh
```

Or just delete `~/Library/Services/Convert TS to MP4.workflow` and `~/Library/Services/Convert TS to MKV.workflow` manually.

## Manual setup (if you'd rather build it in Automator yourself)

<details>
<summary>Click to expand</summary>

1. Open **Automator** → **File** → **New** → **Quick Action**
2. Set **Workflow receives current** to `files or folders` **in** `Finder`
3. Drag in a **Run Shell Script** action
4. **Shell:** `/bin/zsh`, **Pass input:** `as arguments`
5. Paste (MP4 variant):

   ```sh
   PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
   for f in "$@"; do
     case "$f" in
       *.ts|*.TS)
         tag=()
         [ "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$f")" = "hevc" ] && tag=(-tag:v hvc1)
         ffmpeg -y -i "$f" -map 0:v -map "0:a?" -c copy "${tag[@]}" "${f%.*}.mp4"
         ;;
     esac
   done
   osascript -e 'display notification "Done" with title "Convert TS to MP4"'
   ```

   For an MKV variant, drop the `tag` logic and change the output extension to `.mkv`.

6. **File** → **Save** → name it `Convert TS to MP4` (or `Convert TS to MKV`)

</details>

## License

[MIT](LICENSE)
