# doors for Mac — 2.4

A native macOS fan adaptation of [Ixar's Windows RANS0M](https://github.com/Ixars/ransomdoors), itself inspired by RANSOM/A-90 from *Doors* by LSPLASH. Unofficial, non-commercial, and not affiliated with LSPLASH.

## What happens

The warning appears as soon as the app starts. The game advances to the red attack and `DOWNLOADING` effect automatically after three seconds, or sooner if the player moves the mouse or presses a key. There is no start/settings/replay menu. A floating ransom window then appears with a wall-clock countdown, escalating music from the original project, and recurring short-lived pop-up images (more frequent in the last 20 seconds). The app creates harmless `.gold1`–`.gold6` marker files with the original gold image as their Finder icon and one `.crucifix` to find and drag onto the ransom window. The same files can be chosen with **Выбрать файл…**. A real marker is consumed only once. The very first drawer always contains exactly one 10G coin; many later drawers are empty decoys.

The markers are created only inside the app's own `~/Library/Application Support/RANS0M Mac/Rounds` folder, with 30 colorful drawers. The folder is opened automatically in Finder during the round. It never writes to system `/Applications` or another system directory. Finder's **Recents** is a virtual view rather than a folder and cannot be a target.

The app keeps a manifest and removes only its own markers and empty game-owned folders on payment, timeout, Quit, or the next launch after a crash. If you put your own file inside one of its folders or change a marker file, it leaves that file alone. It does **not** encrypt, modify, or delete your other files. Paying all the gold shows the original green thank-you image, then exits; the crucifix plays the original sound and displays the monster's defeat first. When the timer runs out, the red monster fills the screen for three seconds, followed by a black full-screen scene for 20 seconds, then the app exits.

The normal close and minimize buttons are disabled during an active round, and the Dock icon disappears when the ransom panel opens. There is no in-game Stop Round/Esc shortcut. **Cmd+Q while the game is focused, and normal macOS Force Quit, remain available for safety.** It does not change the wallpaper/cursor, install a background agent, shut down the Mac, or execute arbitrary commands. It watches input only in its own foreground app window, so no Input Monitoring or Accessibility permission is needed.

## Build

To share with a friend, download the [Mac disk image from the v2.4 release](https://github.com/kbacovski/doors/releases/download/v2.4/doors-for-Mac-2.4.dmg) (choose the DMG under **Assets**, not “Source code”) or send the DMG intact. On a Mac (macOS 13 or later), open the DMG and move `doors.app` to Applications or another folder, then launch it. The bundle includes both Apple silicon and Intel code; the recipient does not need Xcode. The icon uses the original red monster artwork. This is an unofficial fan build, ad-hoc signed but **not Apple-notarized**. Gatekeeper may block its first launch; the recipient should explicitly allow it in macOS Privacy & Security only if they trust the sender and this build. We cannot guarantee friction-free installation without a Developer ID signature and notarization.

For developers, Xcode with a macOS SDK is required to run `./build.sh`, which produces `build/doors.app`. Set `ARCH=arm64` or `ARCH=x86_64` for a single architecture. `IconMaker.swift` can regenerate the 1024px icon artwork from `Resources/ransom_attack.png`; `Resources/doors.icns` is bundled by the build script.

## Credits and license

Original Windows project, art, and audio: **Ixar**, [ransomdoors](https://github.com/Ixars/ransomdoors). *Doors*, RANSOM/A-90, and related original material: **LSPLASH**. This version rebuilds the gameplay and interface in SwiftUI/AppKit. The original `LICENSE.md` is included; it permits non-commercial modifications with credit and forbids resale. Third-party game material remains the property of its owners.
