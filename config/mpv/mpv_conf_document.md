# Documentation: `mpv.conf` Argument Reference

This document is generated by ChatGPT explains the purpose of each configuration
argument typically used in `mpv.conf` for MPV media player across minimal, balanced,
and high-quality setups.

---

## ▶ GPU and Output

- `gpu-api=opengl|vulkan|d3d11` – Selects the graphics API for rendering.

  - `opengl`: Compatible with most hardware, including Intel iGPUs.
  - `vulkan`: Higher performance on supported hardware, especially with NVIDIA.
  - `d3d11`: Used on Windows.

- `gpu-context=auto|x11|wayland` – Sets the windowing system integration for the GPU context.

  - `auto`: Automatically selects the appropriate context.
  - `x11`: Use with X11 window system.
  - `wayland`: Use with Wayland.

- `vo=gpu|xv` – Sets the video output driver.

  - `gpu`: Modern output driver supporting shaders and hardware acceleration.
  - `xv`: Legacy driver for older systems (less preferred).

- `hwdec=vaapi|nvdec|auto` – Hardware video decoding method.

  - `vaapi`: Intel/Linux hardware decoding.
  - `nvdec`: NVIDIA hardware decoding.
  - `auto`: Lets MPV choose the best available decoder.

---

## ▶ Player Behavior

- `keep-open=yes` – Keeps the video window open after playback ends.
- `save-position-on-quit=yes` – Remembers playback position between sessions.
- `autofit=WxH` – Scales the window to a percentage or pixel size of the screen.
- `cursor-autohide=MS` – Hides the mouse cursor after given milliseconds of inactivity.

---

## ▶ Screenshot Settings

- `screenshot-template` – Sets naming pattern for saved screenshots.
- `screenshot-format=png|jpg` – Format for screenshot images.
- `screenshot-png-compression=0–10` – Compression level (0 = no compression).
- `screenshot-tag-colorspace=yes` – Embed color space metadata.
- `screenshot-high-bit-depth=yes` – Matches screenshot bit depth to video.

---

## ▶ On-Screen Display (OSD)

- `osc=no|yes` – Enables/disables MPV's built-in on-screen controller.
- `osd-bar=yes` – Enables the progress bar.
- `osd-font` – Sets the font for OSD text.
- `osd-font-size` – Font size for OSD.
- `osd-color` – ARGB color code for text.
- `osd-border-color` – Border color for OSD text.
- `osd-bar-h/w` – Sets height/width of the progress bar.
- `osd-bar-align-y/x` – Aligns OSD elements vertically/horizontally.
- `osd-status-msg` – Custom format for the OSD status message.

---

## ▶ Subtitles

- `blend-subtitles=no` – Disables subtitle blending to reduce CPU load.
- `sub-ass-vsfilter-blur-compat` – Improves ASS subtitle rendering compatibility.
- `sub-ass-scale-with-window=no` – Keeps subtitles consistent when resizing.
- `sub-auto=fuzzy` – Loads external subtitles even with fuzzy filename matching.
- `sub-file-paths-append=dir` – Adds subtitle search paths.
- `demuxer-mkv-subtitle-preroll=yes` – Shows subtitles immediately after seeking.
- `embeddedfonts=yes` – Uses fonts embedded in video files.
- `sub-fix-timing=no` – Avoids automatic subtitle timing corrections.

### Subtitle Style

- `sub-font` – Font used for subtitles.
- `sub-font-size` – Subtitle font size.
- `sub-blur` – Blur effect on subtitles.
- `sub-border-color` – Border color (RGBA).
- `sub-border-size` – Size of subtitle borders.
- `sub-color` – Main subtitle color.
- `sub-margin-x/y` – Margin from screen edges.
- `sub-shadow-color` – Shadow color.
- `sub-shadow-offset` – Shadow offset.

---

## ▶ Audio

- `volume-max` – Sets the maximum volume (%).
- `audio-stream-silence` – Prevents audio popping during seek.
- `audio-file-auto=fuzzy` – Autoload external audio tracks with fuzzy name match.
- `audio-pitch-correction=yes` – Maintains pitch when changing speed.

---

## ▶ Video Quality & Performance

- `profile=fast|gpu|gpu-hq` – Sets presets for rendering.

  - `fast`: Minimal effects, best performance.
  - `gpu`: Balanced GPU rendering.
  - `gpu-hq`: High-quality GPU rendering with heavier filters.

- `scale`, `cscale`, `dscale`, `tscale` – Filters for scaling:

  - `bilinear`: Fastest, least sharp.
  - `mitchell`: Balanced filter.
  - `ewa_lanczossharp`: High-quality upscale.
  - `ewa_lanczossoft`: Softer version.
  - `oversample`: For tscale.

- `video-sync=display-resample` – Sync video to display refresh rate.

- `interpolation=yes|no` – Enables motion interpolation.

- `tscale-clamp` – Prevents artifacts during interpolation.

---

## ▶ Debanding

- `deband=yes` – Enables banding reduction filter.
- `deband-iterations` – Number of filtering passes.
- `deband-threshold` – Edge detection threshold.
- `deband-range` – Distance in pixels for neighbor samples.
- `deband-grain` – Adds grain to hide remaining banding.

---

## ▶ Dithering

- `dither-depth=auto` – Sets dithering precision automatically based on output bit depth.

---

## ▶ Shaders

- `glsl-shader="path"` – Loads GLSL shader for upscaling/downscaling (e.g. RAVU, KrigBilateral).

---

## ▶ Deinterlacing

- `deinterlace=no` – Disables deinterlacing.

---

## ▶ Protocol Profiles

- `[protocol.http|https|ytdl]` – Profiles for specific stream types.
- `hls-bitrate=max` – Prefer highest quality for HLS streams.
- `cache=no` – Disable caching (useful for live streams).
- `no-cache-pause` – Avoid pausing when the cache depletes.
