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
| Works with any codec inside the `.ts` | ✅ (re-encodes only when needed) | ✅ Always |
| Plays in QuickTime / Finder / iMovie | ✅ | ❌ (use VLC / IINA) |
| Speed | Fast for most sources; HDZero clips re-encode (~10× realtime) | Always fast (pure remux) |
| Recommended for | Sharing, editing, AirDrop | Anything exotic, or when speed matters most |

For HDZero DVR clips the script detects the `yuvj420p` pixel format Apple's decoders refuse to render and re-encodes the video to standard `yuv420p` (audio is still copied). For ordinary H.264 or HEVC sources it does a pure remux. HEVC sources additionally get `-tag:v hvc1` so Apple recognizes the codec.

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
# MKV — always a pure remux.
ffmpeg -y -i input.ts -map 0:v -map "0:a?" -c copy input.mkv

# MP4 — three paths, chosen by the source video stream:
#  yuvj420p (HDZero DVR):    re-encode video to yuv420p, copy audio
#  HEVC:                     remux, tag video as hvc1
#  anything else (H.264 etc): remux as-is
```

The MP4 script probes the source video codec and pixel format with `ffprobe` to pick the right ffmpeg flags:

| Source | MP4 strategy | Why |
|---|---|---|
| H.264 `yuvj420p` (HDZero) | `-filter:v fps=60 -c:v libx264 -pix_fmt yuv420p -color_range tv -c:a copy` | Two fixes in one re-encode: (1) swap the pixel format to standard `yuv420p` — Apple's AVFoundation refuses to render the deprecated full-range JPEG-style YUV and shows black video otherwise; (2) drop from HDZero's native 90 fps to 60 fps, the FPV-editing standard. QuickTime/iMovie can't keep up with 90 fps H.264 at HDZero bitrates and stutters into slow motion during fast scenes. CRF 18 is visually transparent. |
| HEVC | `-c copy -tag:v hvc1` | Apple needs the `hvc1` codec tag (instead of `hev1`) to recognize HEVC in MP4 — without it, the video stream is muxed but plays audio only. |
| Anything else | `-c copy` | Pure remux, lossless, finishes nearly as fast as a file copy. |

`-map "0:a?"` makes the audio track optional, since some sources (including HDZero) have no audio. The quotes matter — zsh would otherwise glob the `?`.

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
         vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$f")
         vpix=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt   -of default=nw=1:nk=1 "$f")
         case "$vpix" in
           yuvj*) vargs=(-filter:v "fps=60" -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p -color_range tv) ;;
           *)     if [ "$vcodec" = "hevc" ]; then vargs=(-c:v copy -tag:v hvc1); else vargs=(-c:v copy); fi ;;
         esac
         ffmpeg -y -i "$f" -map 0:v -map "0:a?" "${vargs[@]}" -c:a copy "${f%.*}.mp4"
         ;;
     esac
   done
   osascript -e 'display notification "Done" with title "Convert TS to MP4"'
   ```

   For an MKV variant, replace all of the codec-selection logic with a single `ffmpeg -y -i "$f" -map 0:v -map "0:a?" -c copy "${f%.*}.mkv"` line and change the output extension to `.mkv`.

6. **File** → **Save** → name it `Convert TS to MP4` (or `Convert TS to MKV`)

</details>

## License

[MIT](LICENSE)
