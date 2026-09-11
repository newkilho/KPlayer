[한국어](README.md) | **English** | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

# KPlayer

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Engine](https://img.shields.io/badge/engine-libmpv-green)
![License](https://img.shields.io/badge/license-GPL--2.0--or--later-lightgrey)

A clean Windows media player — no ads, no adware, no bloat.  
Built on the open-source media engine **libmpv**.

![KPlayer](https://kilho.net/wp-content/uploads/2026/03/K-949.png)

## Features

- **38 formats** — 23 video (MP4, MKV, AVI, MOV, WMV, WebM, TS, M2TS, VOB, RM/RMVB, …),
  12 audio (MP3, FLAC, AAC, M4A, WAV, OGG, Opus, WMA, APE, DSF, …), 3 playlist (M3U, M3U8, PLS)
- Drag and drop files or folders to add them instantly — the player window replaces the list, the playlist window appends
- Reorder playlist items by dragging; repeat and shuffle; the playlist is saved
- Subtitle on/off and track switching; font, color, outline, shadow and position settings
- Chapter navigation, frame stepping, playback speed (0.25×–4.0×), screenshots (PNG/JPG)
- `TAB` info panel — file, codec, resolution, frame rate and more
- Hardware decoding; choice of output driver, graphics API, display sync, upscaler and deinterlacing
- Loudness normalization (selectable strength)
- File associations — register per extension in Settings and open the Windows default-app picker directly
- **Fully customizable keyboard shortcuts and mouse actions** (Settings → Shortcuts / Mouse)
- Multilingual — Korean, English, Japanese, Chinese, Russian, Italian, French, Spanish, Arabic (follows the OS language)
- Frameless dark UI, always on top, automatic update check

## Default Shortcuts

Every key can be changed in Settings → **Shortcuts**. Only `ESC` (leave full screen) and `TAB` (info panel) are fixed.

| Key | Action |
|-----|--------|
| `Space` | Play / pause |
| `Enter` | Full screen |
| `←` / `→` | Seek −5 s / +5 s |
| `Shift` + `←` / `→` | Seek −1 s / +1 s (exact) |
| `Ctrl` + `←` / `→` | Previous / next chapter |
| `,` / `.` | Previous / next frame |
| `↑` / `↓` | Volume +5 / −5 |
| `0` / `9` | Volume +2 / −2 |
| `M` | Mute |
| `Page Up` / `Page Down` | Previous / next file |
| `V` | Show / hide subtitles |
| `J` / `Shift` + `J` | Next / previous subtitle track |
| `S` | Screenshot |
| `Z` | Speed 1.0× |
| `X` / `C` | Speed −0.1 / +0.1 |
| `[` / `]` | Speed −10% / +10% |

Playlist, Settings and Always on top have no default key and are opened from the control bar (a key can be assigned if you like).

## Mouse

Pick a function for each event in Settings → **Mouse** (none · full screen · stretched screen · play/pause · next/previous file · seek forward/back · volume up/down).

| Event | Default |
|-----|--------|
| Left double-click | Full screen / restore |
| Wheel up / down | Volume up / down |
| Left single-click, middle button | None |

Drag anywhere to move the window.

## Settings

| Card | Items |
|-----|--------|
| General | Repeat mode · shuffle · save playlist · screenshot folder/format · always on top · player window size |
| Video | Hardware decoding · output driver · graphics API · display sync · upscaler · deinterlacing |
| Audio | Default volume · loudness normalization · strength |
| Subtitles | Show by default · size · default language · font · bold · color · outline · shadow · vertical position · alignment · prefer subtitle file styles |
| Associations | Register per extension · choose default app |
| Shortcuts | Assign keys for 29 actions |
| Mouse | Click · double-click · middle button · wheel actions |

Settings are stored in `KPlayer.ini` and the playlist in `KPlayer.lst`, next to the executable (portable).

## Installation

The installer puts KPlayer in `%LOCALAPPDATA%\KPlayer`. `libmpv-2.dll`, `KPlayer.lua` and the `Icon\` folder must sit next to the executable.  
To build from source you need Delphi (VCL, Win64) plus [LibMPVDelphi](https://github.com/nbuyer/libmpvdelphi), [Virtual Treeview](https://github.com/JAM-Software/Virtual-TreeView) and [SVGIconImageList](https://github.com/EtheaDev/SVGIconImageList).

## License

GNU GPL v2 or later · Open source · Free to redistribute.  
Third-party components are listed in `THIRD-PARTY-NOTICES.txt`.

## Author

**Kilho.net** · https://v2.kilho.net
