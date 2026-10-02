"""Configure runner-local Godot editor settings without changing the project.

Run after the first headless editor import has created editor_settings-4.x.tres.
Paths come from setup-java/setup-android and the runner's debug keystore step.
"""
import json
import os
from pathlib import Path
import re


def configure():
    java = Path(os.environ["JAVA_HOME"])
    sdk = Path(os.environ.get("ANDROID_SDK_ROOT") or os.environ["ANDROID_HOME"])
    keystore = Path(os.environ["MINDFLIP_DEBUG_KEYSTORE"])
    for dependency in (java / "bin/java", sdk / "platform-tools/adb", keystore):
        if not dependency.is_file():
            raise SystemExit(f"Required Android build dependency is missing: {dependency}")
    version = os.environ["GODOT_VERSION"]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise SystemExit("GODOT_VERSION must be a stable major.minor.patch version")
    major_minor = ".".join(version.split(".")[:2])
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    destination = config / "godot" / f"editor_settings-{major_minor}.tres"
    if not destination.is_file():
        raise SystemExit(f"Run Godot's headless editor import first: {destination} is missing")
    contents = destination.read_text()
    if '[resource]' not in contents or 'type="EditorSettings"' not in contents:
        raise SystemExit("Godot editor configuration is not a valid EditorSettings resource")
    values = {
        "java_sdk_path": str(java),
        "android_sdk_path": str(sdk),
        "debug_keystore": str(keystore),
        "debug_keystore_user": "androiddebugkey",
        "debug_keystore_pass": "android",
    }
    for name, value in values.items():
        key = f"export/android/{name}"
        line = f"{key} = {json.dumps(value)}"
        pattern = rf"^{re.escape(key)} = .*?$"
        if re.search(pattern, contents, flags=re.MULTILINE):
            contents = re.sub(pattern, lambda _: line, contents, flags=re.MULTILINE)
        else:
            contents = contents.rstrip() + "\n" + line + "\n"
    destination.write_text(contents)
    print("Configured runner-local Godot Android export settings from environment paths.")


if __name__ == "__main__":
    configure()
