"""Real-filesystem helper fault tests on isolated signed fixture bundles.

Only the app launcher is replaced with true/false: this is not update GUI/E2E proof.
"""
import hashlib
import plistlib
import re
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / 'Sources/VXDeckCore/Services/AppUpdater.swift'
SCRIPT = re.search(r'helperScript = #"""\n(.*?)\n    """#', SOURCE.read_text(), re.S).group(1)
SCRIPT = '\n'.join(line[4:] if line.startswith('    ') else line for line in SCRIPT.splitlines()) + '\n'


class HelperTests(unittest.TestCase):
    def fixture(self, root):
        target = root / 'Thư mục có khoảng trắng' / 'VXDeck.app'
        stage = target.parent / '.vxdeck_update_fixture' / 'VXDeck.app'
        for app, version, marker in [(target, '1.0.0', 'old'), (stage, '2.0.0', 'new')]:
            (app / 'Contents/MacOS').mkdir(parents=True)
            shutil.copyfile('/usr/bin/true', app / 'Contents/MacOS/VXDeck')
            (app / 'Contents/MacOS/VXDeck').chmod(0o755)
            (app / 'Contents/Resources').mkdir()
            (app / 'Contents/Resources/marker').write_text(marker)
            with (app / 'Contents/Info.plist').open('wb') as out:
                plistlib.dump({'CFBundleIdentifier': 'com.ztools.vxdeck', 'CFBundleExecutable': 'VXDeck',
                               'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': version}, out)
            subprocess.run(['/usr/bin/codesign', '--force', '--deep', '--sign', '-', str(app)], check=True, capture_output=True)
        ready = stage.parent / 'ready'
        receipt = target.parent / '.vxdeck_update_receipt.plist'
        backup = target.parent / '.vxdeck_backup_fixture.app'
        identity = f'{target.stat().st_dev}:{target.stat().st_ino}'
        digest = hashlib.sha256((stage / 'Contents/MacOS/VXDeck').read_bytes()).hexdigest()
        return target, stage, backup, ready, receipt, digest, identity

    def execute(self, failure=False, tamper=False, wrong_identity=False):
        with tempfile.TemporaryDirectory(prefix='vxdeck_helper_fixture_') as folder:
            root = Path(folder)
            target, stage, backup, ready, receipt, digest, identity = self.fixture(root)
            script = root / 'apply_update.sh'
            script.write_text(SCRIPT.replace('/usr/bin/open -n "$target"', ('/usr/bin/false' if failure else '/usr/bin/true')))
            subprocess.run(['/bin/bash', '-n', str(script)], check=True)
            parent = subprocess.Popen(['/bin/sleep', '60'])
            helper = subprocess.Popen(['/bin/bash', str(script), str(parent.pid), str(target), str(stage),
                                       str(backup), str(ready), str(receipt), digest, '2.0.0',
                                       'wrong' if wrong_identity else identity], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                deadline = time.monotonic() + 5
                while not ready.exists() and helper.poll() is None and time.monotonic() < deadline:
                    time.sleep(0.02)
                if wrong_identity:
                    self.assertFalse(ready.exists())
                else:
                    if not ready.exists():
                        _, failure_output = helper.communicate(timeout=2)
                        self.fail('helper must ACK before parent exits: ' + failure_output.decode())
                    self.assertEqual((target / 'Contents/Resources/marker').read_text(), 'old')
                    if tamper:
                        (stage / 'Contents/MacOS/VXDeck').write_bytes(b'tampered')
                parent.terminate(); parent.wait(timeout=2)
                output, error = helper.communicate(timeout=10)
                if wrong_identity:
                    self.assertNotEqual(helper.returncode, 0)
                    self.assertFalse(backup.exists()); self.assertEqual((target/'Contents/Resources/marker').read_text(),'old')
                else:
                    state = plistlib.loads(receipt.read_bytes())['state']
                    if tamper:
                        self.assertEqual(state,'revalidation_failed'); self.assertEqual((target/'Contents/Resources/marker').read_text(),'old')
                    elif failure:
                        self.assertEqual(state,'relaunch_failed_rolled_back')
                        self.assertEqual((target/'Contents/Resources/marker').read_text(),'old'); self.assertEqual((stage/'Contents/Resources/marker').read_text(),'new')
                    else:
                        self.assertEqual(helper.returncode,0,error.decode())
                        self.assertEqual(state,'awaiting_launch_confirmation')
                        self.assertEqual((target/'Contents/Resources/marker').read_text(),'new'); self.assertEqual((backup/'Contents/Resources/marker').read_text(),'old')
            finally:
                for process in [parent, helper]:
                    if process.poll() is None:
                        process.kill(); process.wait(timeout=2)
                if helper.stdout: helper.stdout.close()
                if helper.stderr: helper.stderr.close()

    def test_success_retains_backup_and_waits_for_real_launch_confirmation(self): self.execute()
    def test_relaunch_failure_rolls_back_without_deleting_either_bundle(self): self.execute(failure=True)
    def test_stage_tampering_after_ack_never_replaces_current_app(self): self.execute(tamper=True)
    def test_changed_target_identity_rejected_before_ack(self): self.execute(wrong_identity=True)


if __name__ == '__main__': unittest.main()
