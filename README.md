# Convert TS to MP4 / MKV — macOS Quick Actions

Right-click any `.ts` file in Finder and convert it to `.mp4` or `.mkv` with a single click, powered by `ffmpeg`.

```
Finder ▸ right-click  ▸  Quick Actions  ▸  Convert TS to MP4 (60 fps)
                                       ▸  Convert TS to MP4 (90 fps)
                                       ▸  Convert TS to MKV
```

A native macOS notification fires when the conversion finishes. The original `.ts` file is left untouched.

---

## Which one should I use?

| | **MP4 (60 fps)** | **MP4 (90 fps)** | **MKV** |
|---|---|---|---|
| Plays in QuickTime / Finder / iMovie | ✅ | ⚠️ stutters into slo-mo on high-rate sources | ❌ (use VLC / IINA) |
| Plays smoothly in IINA / VLC | ✅ | ✅ | ✅ |
| Preserves source frame rate | drops to 60 fps if source needs re-encoding | ✅ | ✅ |
| Re-encodes the video | only when needed (e.g. HDZero `yuvj420p`) | only when needed (e.g. HDZero `yuvj420p`) | never |
| Best for | editing in iMovie / Final Cut / QuickTime playback | smooth high-rate playback in IINA / VLC | fast, exact archival copy |

The two MP4 actions are identical except for the output frame rate when a re-encode is required. For ordinary H.264 or HEVC sources, both MP4 actions just remux (no fps change). MKV is always a pure remux.

For HDZero DVR clips the script detects the `yuvj420p` pixel format Apple's decoders refuse to render and re-encodes the video to standard `yuv420p` (audio is still copied). For HEVC sources it adds `-tag:v hvc1` so Apple recognizes the codec.

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
2. Build `Convert TS to MP4 (60 fps).workflow`, `Convert TS to MP4 (90 fps).workflow`, and `Convert TS to MKV.workflow` into `~/Library/Services/`
3. Remove any legacy `Convert TS to MP4.workflow` left over from before the 60/90 split
4. Refresh the macOS Services menu so the Quick Actions show up immediately

If the menu items don't appear right away, run `killall Finder` or log out and back in. macOS also requires you to tick each Quick Action's checkbox the first time, under **System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders**.

## Usage

1. Open Finder and select one or more `.ts` files (multi-select works)
2. Right-click → **Quick Actions** → pick **Convert TS to MP4 (60 fps)**, **(90 fps)**, or **MKV**
3. Wait for the notification

Each output lands next to its source: `clip.ts` → `clip.mp4` / `clip.mkv`. Existing files with the same name are overwritten (`ffmpeg -y`). The originals are not deleted.

## How it works

The Quick Actions are Automator **Run Shell Script** actions. The MKV one is always a pure remux:

```sh
ffmpeg -y -i input.ts -map 0:v -map "0:a?" -c copy input.mkv
```

The two MP4 actions share a single template parameterized by target fps (60 or 90). They probe the source video codec and pixel format with `ffprobe` and pick one of three strategies:

| Source | MP4 strategy | Why |
|---|---|---|
| H.264 `yuvj420p` (HDZero) | `-filter:v fps=<60\|90> -c:v libx264 -pix_fmt yuv420p -color_range tv -bf 0 -g <60\|90> -c:a copy` | Apple's AVFoundation refuses to render the deprecated full-range JPEG-style YUV and shows black video otherwise — so we re-encode to standard `yuv420p`. The fps filter lets you choose: 60 fps for smooth playback in QuickTime/iMovie (90 fps H.264 at HDZero bitrates stutters into slo-mo there), or 90 fps to preserve the source rate for IINA/VLC. CRF 18 is visually transparent. |
| HEVC | `-c copy -tag:v hvc1` | Apple needs the `hvc1` codec tag (instead of `hev1`) to recognize HEVC in MP4 — without it, the video stream is muxed but plays audio only. The fps choice has no effect on HEVC sources; they remux as-is. |
| Anything else (e.g. ordinary H.264) | `-c copy` | Pure remux, lossless, finishes nearly as fast as a file copy. The fps choice has no effect here either. |

`-map "0:a?"` makes the audio track optional, since some sources (including HDZero) have no audio. The quotes matter — zsh would otherwise glob the `?`.

If a `.ts` file contains streams MP4 can't carry (e.g. some flavors of MPEG-2, AC-3 audio), the MP4 mux will fail and you'll get a "failed" notification — try the MKV action instead.

## Uninstall

```sh
./uninstall.sh
```

Or just delete the relevant `.workflow` bundles in `~/Library/Services/` manually:

- `Convert TS to MP4 (60 fps).workflow`
- `Convert TS to MP4 (90 fps).workflow`
- `Convert TS to MKV.workflow`
- `Convert TS to MP4.workflow` (legacy, only present if you installed an older version)

## Manual setup (if you'd rather build it in Automator yourself)

<details>
<summary>Click to expand</summary>

1. Open **Automator** → **File** → **New** → **Quick Action**
2. Set **Workflow receives current** to `files or folders` **in** `Finder`
3. Drag in a **Run Shell Script** action
4. **Shell:** `/bin/zsh`, **Pass input:** `as arguments`
5. Paste (MP4 variant — change `FPS=60` to `FPS=90` for the 90 fps Quick Action):

   ```sh
   PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
   FPS=60
   for f in "$@"; do
     case "$f" in
       *.ts|*.TS)
         vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$f")
         vpix=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt   -of default=nw=1:nk=1 "$f")
         case "$vpix" in
           yuvj*) vargs=(-filter:v "fps=$FPS" -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p -color_range tv -bf 0 -g "$FPS" -fps_mode cfr) ;;
           *)     if [ "$vcodec" = "hevc" ]; then vargs=(-c:v copy -tag:v hvc1); else vargs=(-c:v copy); fi ;;
         esac
         ffmpeg -y -fflags +genpts -i "$f" -map 0:v -map "0:a?" "${vargs[@]}" -c:a copy "${f%.*}.mp4"
         ;;
     esac
   done
   osascript -e "display notification \"Done\" with title \"Convert TS to MP4 (${FPS} fps)\""
   ```

   For an MKV variant, replace all of the codec-selection logic with a single `ffmpeg -y -i "$f" -map 0:v -map "0:a?" -c copy "${f%.*}.mkv"` line and change the output extension to `.mkv`.

6. **File** → **Save** → name it `Convert TS to MP4 (60 fps)`, `Convert TS to MP4 (90 fps)`, or `Convert TS to MKV`

</details>

## License

[MIT](LICENSE)
