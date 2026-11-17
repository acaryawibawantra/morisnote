# <img src="https://github.com/saber-notes/saber/raw/main/assets/icon/icon.png" width="30" height="30" alt="Logo"> Saber

[<img src='https://github.com/saber-notes/saber/blob/main/assets_raw/badges/google-play-badge.svg'
    alt='Get it on Google Play'
    height=50>][google_play]
&nbsp;
[<img src="https://github.com/saber-notes/saber/blob/main/assets_raw/badges/f-droid-badge.svg"
    alt="Get it on F-Droid"
    height=50>][f-droid]
&nbsp;
[<img src="https://github.com/saber-notes/saber/blob/main/assets_raw/badges/app-store-badge.svg"
    alt="Download on the App Store"
    height=50>][app_store]
&nbsp;
[<img src="https://github.com/saber-notes/saber/blob/main/assets_raw/badges/windows-badge.png"
    alt="Download for Windows"
    height=50>][download_windows]
&nbsp;
[<img src="https://github.com/saber-notes/saber/blob/main/assets_raw/badges/flathub-badge.svg"
    alt="Download on Flathub"
    height=50>][flathub]
&nbsp;
[<img src="https://github.com/saber-notes/saber/blob/main/assets_raw/badges/appimage-logo.svg"
    alt="Get it as an AppImage"
    height=50>][download_appimage]

[English](https://github.com/saber-notes/saber/blob/main/README.md) |
[čeština](https://github.com/saber-notes/saber/blob/main/README-cs.md) |
[Deutsch](https://github.com/saber-notes/saber/blob/main/README-de.md) |
[中文 (简体中文, 中国)](https://github.com/saber-notes/saber/blob/main/README-zh-CN.md) |
[中文 (繁體, 台灣)](https://github.com/saber-notes/saber/blob/main/README-zh-TW.md) |
[العربية](https://github.com/saber-notes/saber/blob/main/README-ar.md) |
[Tiếng Việt](https://github.com/saber-notes/saber/blob/main/README-vi.md) |
[Bahasa Indonesia](https://github.com/saber-notes/saber/blob/main/README-id.md)

> ## Morisnote — personal build
>
> This repository is a **personal fork** of [Saber](https://github.com/saber-notes/saber)
> (GPL-3.0) for private use on one Android tablet. Package id
> `com.acaryawibawantra.morisnote` so it installs alongside the Play Store app.
> APKs are built by `.github/workflows/morisnote-apk.yml` and sideloaded.
>
> Modifications in this fork are made by **Hermes Agent** (Nous Research) under
> the direction of I Dewa Nyoman Acarya Wibawantra. Upstream Saber is by
> Adil Hanney and contributors; see [LICENSE.md](LICENSE.md).
>
> ### Download APK
>
> **[⬇️ Unduh build terbaru (APK arm64)](../../releases/latest)**
>
> Cara pasang di tablet (Xiaomi Pad):
> 1. Buka tautan di atas di browser tablet (perlu login GitHub karena repo ini
>    privat), unduh `Morisnote.apk`.
> 2. Buka File Manager → ketuk APK → izinkan **"Install unknown apps"** bila
>    diminta.
> 3. Pasang. Build berikutnya bisa dipasang **di atas** build lama (tanda tangan
>    sama) tanpa kehilangan catatan — jangan uninstall dulu.
>
> ### What this fork adds
>
> **Writing**
> - **18 paper templates** (upstream has 9): graph paper, isometric, hexagon,
>   weekly planner, daily planner, checklist, storyboard, calligraphy guides,
>   half lined, on top of the existing ones.
> - **Stylus-only drawing**: the pen always inks, the finger always pans/zooms.
> - **Palm rejection**: wide touch contacts never draw.
> - **Scribble to erase**: scribble quickly over ink to delete the strokes it
>   crosses (only strokes it actually crosses, never on an empty page).
> - **Two-finger tap** deletes the stroke you just drew.
> - **Snap to shape**: a confident circle, rectangle, triangle or star becomes
>   a clean shape when the pen lifts.
> - **Angle ruler**: locks every new stroke to a chosen angle.
> - **Paper tint**: cream, sepia, mint or dark pages.
>
> **Studying**
> - **Streak api** 🔥: every saved note lights the day; a missed day puts the
>   fire out. Home app bar shows the flame, a 14-day strip and the best run.
> - **Focus timer**: 25/50 minute sessions that keep running while you write.
> - **Recall mode**: select strokes with the lasso and hide them into faint
>   ghosts, then reveal everything to check yourself. Saved in the note.
> - **Voice notes per page**: record, play back, and jump the recording to the
>   exact moment a stroke was drawn.
> - **Search notes by name** from the home app bar.
> - **Rolling backups**: one copy per note per day in
>   `Documents/MorisnoteBackup/<date>/`, last 7 days kept.

Saber is the notes app built for handwriting.

It's designed to be as simple and intuitive as possible, while still delivering unique features that you'll actually use. Additionally, Saber is available across all your devices, large and small, and syncs between them seamlessly.

Notably, it can invert your notes when you're in dark mode. This allows you to write with white ink on a black background, which is much easier on the eyes in low-light environments like when the teacher turns off the lights in class.
Images and PDFs are also inverted, so you can still use a digital printout or a textbook without the fuss.

Saber uses a dual-password system to protect your notes from anyone but you, even if they have complete control over the server. You can safely store your notes on the official Saber server, another server, or even host your own!

The app is completely open-source so that anyone can view the source code and see exactly what it's doing and how it handles your data. Many other note-taking apps are closed-source and proprietary, meaning that their inner workings are a mystery to the public.

As someone who studies maths, highlighting multi-line equations was always a hassle with other apps, where the highlighter would change color when it overlapped with itself. Another problem I had was that in some apps, the highlighter would render on top of the text, fading it out and making it hard to read.
Saber's highlighter has no such issues. It utilizes canvas compositing to render the highlighter in a way that is consistent with/better than traditional paper, where it handles overlaps and maintains color consistency.

Saber has everything you need to keep your notes organized. Create folders inside folders inside folders to your heart's content with no limit on the number of nested folders. And even though a note may be buried deep within a nested folder, you can still access it easily with your most recent notes always available on the home screen.

Discover a whole new way to capture and organize your thoughts with Saber. Whether you're a student, professional, or creative mind, Saber is your trusted companion for digital handwriting. Download now and let your ideas flow freely!

[![Latest release](https://img.shields.io/github/v/release/saber-notes/saber)](https://github.com/saber-notes/saber/releases/latest)
[![Flathub](https://img.shields.io/flathub/v/com.adilhanney.saber)](https://flathub.org/apps/details/com.adilhanney.saber)
[![F-Droid](https://img.shields.io/f-droid/v/com.adilhanney.saber)](https://f-droid.org/en/packages/com.adilhanney.saber/)
[![GitHub downloads](https://img.shields.io/github/downloads/saber-notes/saber/total?label=GitHub%20downloads)](https://github.com/saber-notes/saber/releases)
[![Flathub downloads](https://img.shields.io/flathub/downloads/com.adilhanney.saber?label=Flathub%20downloads)](https://flathub.org/apps/details/com.adilhanney.saber)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/adil192)](https://github.com/sponsors/adil192)
[![License](https://img.shields.io/github/license/saber-notes/saber)](https://github.com/saber-notes/saber/blob/main/LICENSE.md)
[![Translation status](https://hosted.weblate.org/widget/saber-notes/saber/svg-badge.svg)](https://hosted.weblate.org/engage/saber-notes/)
[![Codecov](https://codecov.io/gh/saber-notes/saber/branch/main/graph/badge.svg?token=EGQSN0THW2)](https://codecov.io/gh/saber-notes/saber)

<details open>
<summary>Tap to show/hide screenshots</summary>

<div>
<img src="https://github.com/saber-notes/saber/raw/main/metadata/en-US/images/phoneScreenshots/1_home.png" width="180">
<img src="https://github.com/saber-notes/saber/raw/main/metadata/en-US/images/phoneScreenshots/2_editor.png" width="180">
<img src="https://github.com/saber-notes/saber/raw/main/metadata/en-US/images/phoneScreenshots/3_login.png" width="180">
<img src="https://github.com/saber-notes/saber/raw/main/metadata/en-US/images/phoneScreenshots/4_settings.png" width="180">
</div>
</details>

## Features

Please see [#1 Saber progress][progress].

## Install

Please see
[Install Saber](https://github.com/saber-notes/saber/wiki/install)
on the wiki.

## Build from source

Please see
[Build Saber](https://github.com/saber-notes/saber/wiki/build)
on the wiki.

## Links

- [Nextcloud server][nextcloud]
- [Privacy policy][privacy]
- [License][license]
- [Releases][releases]

## Translating

All translations are thanks to our community of contributors.

If you'd like to help out translating Saber, head to [Weblate](https://hosted.weblate.org/engage/saber-notes/)!

[![Translation status](https://hosted.weblate.org/widget/saber-notes/multi-auto.svg)](https://hosted.weblate.org/engage/saber-notes/)

Note: To avoid falling back to English, any gaps in the translations are filled
in by machine translation until a human can contribute.

## Supporting Saber

If you like Saber, please consider supporting it by:
- Spreading the word!
- Starring the project on GitHub
- Sponsoring me on [GitHub Sponsors](https://github.com/sponsors/adil192)
- Donating via [PayPal](https://paypal.me/adilhanney)
- Buying more storage on the Nextcloud server: see [Pricing](pricing.md)

## Development notes

Please see
[Maintainer notes](https://github.com/saber-notes/saber/wiki/Maintainer-notes)
on the wiki.


[f-droid]: https://f-droid.org/packages/com.adilhanney.saber/
[flathub]: https://flathub.org/apps/details/com.adilhanney.saber
[google_play]: https://play.google.com/store/apps/details?id=com.adilhanney.saber
[snap]: https://snapcraft.io/saber
[app_store]: https://apps.apple.com/us/app/saber/id1671523739
[download_windows]: https://github.com/saber-notes/saber/releases/download/v1.37.1/SaberInstaller_v1.37.1.exe
[download_appimage]: https://github.com/saber-notes/saber/releases/download/v1.37.1/Saber-1.37.1-x86_64.AppImage

[nextcloud]: https://nc.saber.adil.hanney.org/

[privacy]: https://github.com/saber-notes/saber/blob/main/privacy_policy.md
[license]: https://github.com/saber-notes/saber/blob/main/LICENSE.md

[releases]: https://github.com/saber-notes/saber/releases
[issues]: https://github.com/saber-notes/saber/issues
[progress]: https://github.com/saber-notes/saber/discussions/1

[f-droid-manifest]: https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/com.adilhanney.saber.yml
