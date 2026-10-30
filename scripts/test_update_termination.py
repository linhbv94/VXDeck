"""Native AppKit/SwiftUI regression; isolated app, no downloads or installed app changes."""
import os
import pathlib
import plistlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
cache = pathlib.Path(tempfile.gettempdir()) / 'vxdeck_update_termination_cache'
cache.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='vxdeck_termination_') as directory:
    root = pathlib.Path(directory)
    app = root / 'termination_fixture.app'
    binary = app / 'Contents/MacOS/termination_fixture'
    binary.parent.mkdir(parents=True)
    (app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
        'CFBundleIdentifier': 'com.ztools.vxdeck.termination_fixture',
        'CFBundleExecutable': binary.name, 'CFBundlePackageType': 'APPL',
    }))
    env = dict(os.environ, CLANG_MODULE_CACHE_PATH=str(cache / 'clang_cache'))
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', str(cache / 'swift_cache'),
                    str(ROOT / 'Sources/VXDeckCore/Services/update_application_termination.swift'),
                    str(ROOT / 'Tests/native_fixtures/update_termination_fixture.swift'),
                    '-o', str(binary)], check=True, env=env, timeout=180)
    for mode, expected in [('baseline', 42), ('notice', 0), ('settings_fixed', 0)]:
        result = subprocess.run([str(binary), mode], capture_output=True, text=True, timeout=15)
        print(result.stdout, end='')
        if result.returncode != expected:
            raise AssertionError(f'{mode}: expected {expected}, got {result.returncode}: {result.stderr}')
        if mode != 'baseline' and 'terminated' not in result.stdout:
            raise AssertionError(f'{mode}: termination delegate did not run')
    print('PASS: baseline sheet blocks quit; notice and fixed Settings exit through AppKit delegate')
