# Android configuration and reproducible export

Application `MindFlip`, package `com.mindflip.game`, version `0.1.0` / code 1.
Godot 4.6.3 Compatibility renderer. Native APK template export (no Gradle required
for this debug APK). Manifest verification: minimum SDK **24**, target/compile
SDK **36**, `screenOrientation=landscape` (enum 0), arm64-v8a and x86_64.
Immersive/fullscreen is set in the Android export; native screen safe-area
insets are converted to logical UI coordinates. Android fullscreen override is
separate from the normal resizable desktop window. Canvas expansion preserves
large touch targets at 16:9, 20:9, 16:10 and 4:3 landscape sizes.

Only `VIBRATE` is requested, for a 12ms rotation tick. No Internet/storage permission.
App-private persistence uses `user://`. Android background/resume notifications
checkpoint and pause the puzzle; resume requires an explicit Resume press.

## Standard development machine

Install Godot **4.6.3** and matching official export templates. Install a JDK
(17 recommended by Godot; this environment successfully used OpenJDK 21) and an
Android SDK with platform-tools and build-tools 36.0.0. Set Godot Editor Settings:

- Export → Android → Java SDK Path: your JDK root.
- Export → Android → Android SDK Path: your SDK root.

Godot normally generates the standard development debug keystore. Keep private
release keys/passwords outside the repository. Then:

```sh
mkdir -p builds
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug Android builds/MindFlip-debug.apk
apksigner verify --verbose builds/MindFlip-debug.apk
zipalign -c 4 builds/MindFlip-debug.apk
adb install -r builds/MindFlip-debug.apk
```

## Build environment used here

`godot` is 4.6.3. Official `android_debug.apk`, `android_release.apk` and Linux
export templates were installed into `~/.local/share/godot/export_templates/4.6.3.stable`.
The restricted environment has no privileged package installation or connected
Android device. Real Ubuntu-packaged Android tools were downloaded and extracted
under `/tmp/rpg-runtime` during the initial tool setup (the path name is an
abandoned-task setup artifact outside the repository; it contains SDK tools only).
A minimal non-Gradle tool layout at `/tmp/mindflip-sdk` supplies adb, apksigner and
zipalign. Godot used Java 21 and build-tools-directory fallback 35.0.0 with the
real apksigner 31.0.2. The engine template determines SDK 24/36. Godot itself aligns
APK entries. Its export and independent signature/alignment checks succeeded.
These machine-specific paths are Editor Settings, not committed project paths.
On a normal machine use the standard full SDK above, not these temporary wrappers.

Successful output: `/workspace/MindFlip/builds/MindFlip-debug.apk`.
A `.idsig` sidecar may also be emitted; the APK can be installed without it.
This is a debug-signed build, not a Play release. Signature schemes v2 and v3 verify.

## Eventual signed APK/AAB

In Godot, install the Android build template from the Project menu, enable
`gradle_build/use_gradle_build`, select AAB, and configure your owner-controlled
release keystore via local credentials/environment variables. Install platform
36, build-tools 36.0.0, command-line tools, NDK r29 (29.0.14206865) and CMake as
required by Godot's installed build template. Use its bundled Gradle wrapper.
Set min/target SDK overrides only with Gradle enabled; native template export
uses its compiled defaults. Keep code/name versioning updated for each store build.

```sh
godot --headless --path . --export-release Android builds/MindFlip.aab
```

Do this after selecting AAB and supplying release credentials; the current preset
intentionally produces debug APKs without shipping a release private key. Gradle
AAB export and Play submission were not performed in this task. Perform device
QA and check current Play requirements before release, including accessibility,
16KB native library support, store imagery and signing ownership.
