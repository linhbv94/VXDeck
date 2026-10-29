#!/usr/bin/env python3
"""Sign exact manifest payload bytes. No key material is printed or uploaded here."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization


def sign_manifest(package, version, architecture, secret):
    import re
    if not re.fullmatch(r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', version):
        raise ValueError('invalid stable version')
    if architecture not in ('macos_silicon', 'macos_intel'):
        raise ValueError('invalid architecture')
    expected = f'vxdeck_{version}_{architecture}.dmg'
    if package.name != expected or not 0 < package.stat().st_size <= 512 * 1024 * 1024:
        raise ValueError('invalid updater package')
    key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(secret.strip(), validate=True))
    trust_source = (Path(__file__).resolve().parents[1] / 'Sources/VXDeckCore/Services/UpdaterTrust.swift').read_text()
    public = base64.b64encode(key.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)).decode()
    if f'"{public}"' not in trust_source:
        raise ValueError('signing key does not match compiled trust anchor')
    digest = hashlib.sha256()
    with package.open('rb') as stream:
        for chunk in iter(lambda: stream.read(65536), b''):
            digest.update(chunk)
    entry = {'url': f'https://github.com/linhbv94/VXDeck/releases/download/v{version}/{expected}',
             'size': package.stat().st_size, 'sha256': digest.hexdigest()}
    payload = {'app_id': 'com.ztools.vxdeck', 'version': version, 'platforms': {architecture: entry}}
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
    # Compatibility metadata is for old clients; new clients trust only signed_payload.
    return {'version': version, 'tag_name': f'v{version}', 'download_url': entry['url'],
            'html_url': f'https://github.com/linhbv94/VXDeck/releases/tag/v{version}',
            'size': entry['size'], 'sha256': entry['sha256'],
            'signed_payload': base64.b64encode(raw).decode(),
            'signature': base64.b64encode(key.sign(raw)).decode()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--architecture', choices=['macos_silicon', 'macos_intel'], required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    key_file = os.environ.get('VXDECK_SIGNING_KEY_FILE')
    secret = Path(key_file).read_bytes() if key_file else os.environ['VXDECK_SIGNING_PRIVATE_KEY'].encode()
    document = sign_manifest(args.package, args.version, args.architecture, secret)
    args.output.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
