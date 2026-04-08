# 🐈NotchCatwalk🐈

A cat patrols around your MacBook notch.

<p align="center">
  <img src="cat.gif" alt="NotchCatwalk demo" width="480">
</p>

## What is this?

A tiny macOS app that places a cat around your MacBook's notch. The cat walks back and forth along the notch outline, leaving sparkle trails behind. Hover your mouse near the notch to reveal it.

- Notch area expands with a spring animation on hover
- Cat walks along the concave shape of the notch
- Sparkle trail (✦) fades behind the cat
- Hides automatically when your mouse moves away

## Build & Run

Single file, no dependencies, no Xcode project needed:

```bash
./build.sh
open NotchCatwalk.app
```

Requires macOS 14.0+ and a MacBook with a notch.

> **Note**: On first run, macOS will prompt for Accessibility permission
> (System Settings > Privacy & Security > Accessibility). This is needed
> for mouse tracking near the notch. Grant it to "NotchCatwalk".

To quit: `pkill NotchCatwalk`.

## How it works

1. A transparent `NSPanel` is placed over the notch area
2. `NSEvent.addGlobalMonitorForEvents(.mouseMoved)` detects mouse proximity
3. On hover, the black background expands with `.spring()` animation and the cat appears
4. The cat follows waypoints tracing the notch's concave shape
5. On mouse leave, everything shrinks back behind the notch

## Acknowledgments

Inspired by [Atoll](https://github.com/Ebullioscopic/Atoll)'s Dynamic Island for macOS concept.

## License

MIT
