[한국어](README.md) | [English](README.en.md) | [日本語](README.ja.md) | **简体中文**

# KPlayer

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Engine](https://img.shields.io/badge/engine-libmpv-green)
![License](https://img.shields.io/badge/license-GPL--2.0--or--later-lightgrey)

没有广告、没有捆绑软件、没有多余功能的简洁 Windows 媒体播放器。  
基于开源媒体引擎 **libmpv**。

![KPlayer](https://kilho.net/wp-content/uploads/2026/03/K-949.png)

## 功能

- **38 种格式** — 视频 23 种 (MP4, MKV, AVI, MOV, WMV, WebM, TS, M2TS, VOB, RM/RMVB 等)、
  音频 12 种 (MP3, FLAC, AAC, M4A, WAV, OGG, Opus, WMA, APE, DSF 等)、播放列表 3 种 (M3U, M3U8, PLS)
- 拖放文件或文件夹即可添加 — 拖到主窗口替换列表，拖到播放列表窗口则追加
- 拖动调整播放列表顺序，循环播放与随机播放，播放列表自动保存
- 字幕开关与轨道切换，字体、颜色、描边、阴影、位置设置
- 章节跳转、逐帧步进、播放速度 (0.25×–4.0×)、截图 (PNG/JPG)
- `TAB` 信息面板 — 文件、编解码器、分辨率、帧率等
- 硬件解码，可选输出驱动、图形 API、画面同步、放大算法、反交错
- 音量标准化 (可选强度)
- 文件关联 — 在设置中按扩展名注册，并直接打开 Windows 默认应用选择窗口
- **快捷键与鼠标操作均可自定义** (设置 → 快捷键 / 鼠标)
- 多语言 — 韩语、英语、日语、中文、俄语、意大利语、法语、西班牙语、阿拉伯语 (跟随系统语言)
- 无边框深色界面、窗口置顶、自动检查新版本

## 默认快捷键

所有按键都可在设置 → **快捷键** 中更改。只有 `ESC` (退出全屏) 和 `TAB` (信息面板) 固定不变。

| 按键 | 动作 |
|-----|--------|
| `Space` | 播放 / 暂停 |
| `Enter` | 全屏 |
| `←` / `→` | 后退 / 前进 5 秒 |
| `Shift` + `←` / `→` | 后退 / 前进 1 秒 (精确) |
| `Ctrl` + `←` / `→` | 上一 / 下一章节 |
| `,` / `.` | 上一 / 下一帧 |
| `↑` / `↓` | 音量 +5 / −5 |
| `0` / `9` | 音量 +2 / −2 |
| `M` | 静音 |
| `Page Up` / `Page Down` | 上一个 / 下一个文件 |
| `V` | 显示 / 隐藏字幕 |
| `J` / `Shift` + `J` | 下一 / 上一字幕轨道 |
| `S` | 截图 |
| `Z` | 速度 1.0× |
| `X` / `C` | 速度 −0.1 / +0.1 |
| `[` / `]` | 速度 −10% / +10% |

播放列表、设置、窗口置顶没有默认按键，通过控制栏按钮打开 (也可以自行指定按键)。

## 鼠标

在设置 → **鼠标** 中为每个事件选择功能 (无操作、全屏、铺满屏幕、播放/暂停、下一个/上一个文件、前进/后退、音量增大/减小)。

| 事件 | 默认值 |
|-----|--------|
| 左键双击 | 全屏 / 还原 |
| 滚轮向上 / 向下 | 音量增大 / 减小 |
| 左键单击、中键 | 无操作 |

拖动窗口任意位置即可移动。

## 设置

| 卡片 | 项目 |
|-----|--------|
| 常规 | 循环模式、随机播放、保存播放列表、截图文件夹/格式、窗口置顶、播放窗口大小 |
| 视频 | 硬件解码、输出驱动、图形 API、画面同步、放大算法、反交错 |
| 音频 | 默认音量、音量标准化、强度 |
| 字幕 | 默认显示、大小、默认语言、字体、粗体、文字颜色、描边、阴影、垂直位置、对齐、优先使用字幕文件样式 |
| 关联 | 按扩展名注册、选择默认应用 |
| 快捷键 | 为 29 种动作指定按键 |
| 鼠标 | 单击、双击、中键、滚轮动作 |

设置保存在 `KPlayer.ini`，播放列表保存在 `KPlayer.lst`，均位于可执行文件旁 (便携)。

## 安装

安装程序将 KPlayer 放在 `%LOCALAPPDATA%\KPlayer`。可执行文件旁必须有 `libmpv-2.dll`、`KPlayer.lua` 和 `Icon\` 文件夹。  
从源码构建需要 Delphi (VCL, Win64) 以及 [LibMPVDelphi](https://github.com/nbuyer/libmpvdelphi)、[Virtual Treeview](https://github.com/JAM-Software/Virtual-TreeView)、[SVGIconImageList](https://github.com/EtheaDev/SVGIconImageList)。

## 许可证

GNU GPL v2 或更高版本 · 开源 · 可自由再分发。  
所用开源组件列表见 `THIRD-PARTY-NOTICES.txt`。

## 作者

**Kilho.net** · https://v2.kilho.net
