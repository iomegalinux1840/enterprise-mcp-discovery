import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1] / 'skills/enterprise-mcp-discovery/scripts'
sys.path.insert(0, str(SCRIPTS))
from discover_folders import inventory
from inventory_utils import sanitize_url


class DiscoveryTests(unittest.TestCase):
    def test_folder_map_survives_filter(self):
        data = {'mounted_shares': [{'mount_point': '/Volumes/Invoices'}],
                'open_folders': ['/Volumes/Invoices/2026'],
                'folder_candidates': [{'path': '/Volumes/Invoices/2026'}],
                'collection_errors': [{'source': 'browser'}]}
        p = subprocess.run([sys.executable, str(SCRIPTS/'filter_productivity.py')],
                           input='\ufeff'+json.dumps(data), text=True, capture_output=True, check=True)
        out = json.loads(p.stdout)
        for key, value in data.items():
            self.assertEqual(out[key], value)

    def test_windows_bom_merge_in_place_and_url_redaction(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve(); inv = root/'inventory.json'; tabs = root/'tabs.json'
            inv.write_text(json.dumps({'mounted_shares': ['share'], 'collection_errors': []}), encoding='utf-8-sig')
            tabs.write_text(json.dumps({'browser_tabs': [{'url': 'https://user:secret@example.com/invoices?token=secret#secret'}], 'collection_errors': [{'source': 'denied'}]}), encoding='utf-8-sig')
            subprocess.run([sys.executable, str(SCRIPTS/'merge_inventory.py'), str(inv), str(tabs), str(inv)], check=True)
            out = json.loads(inv.read_text())
            self.assertEqual(out['browser_tabs'][0]['url'], 'https://example.com/invoices')
            self.assertEqual(out['mounted_shares'], ['share'])
            self.assertEqual(out['collection_errors'], [{'source': 'denied'}])

    def test_urls(self):
        self.assertEqual(sanitize_url('javascript:alert(1)'), '')
        self.assertEqual(sanitize_url('https://[::1]:8000/path?q=secret'), 'https://[::1]:8000/path')
        self.assertEqual(sanitize_url('https://example.com:bad/'), '')

    def test_folder_metadata_exclusions_links_and_missing_roots(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve(); (root/'Invoices').mkdir(); (root/'HR').mkdir()
            (root/'Invoices'/'sample.pdf').write_bytes(b'private data')
            (root/'HR'/'private.xlsx').write_bytes(b'never inspect')
            (root/'link').symlink_to(root/'HR', target_is_directory=True)
            out = inventory([str(root), str(root/'missing')], [str(root/'HR')])
            rows = out['roots'][0]['folders']
            self.assertEqual(next(r for r in rows if r['path'].endswith('Invoices'))['extensions'], {'.pdf': 1})
            self.assertFalse(any(r['path'].endswith('HR') for r in rows))
            self.assertTrue(any(r['reason']=='link_or_cloud_placeholder' for r in out['roots'][0]['skipped']))
            self.assertEqual(out['roots'][1]['status'], 'unavailable')
            self.assertNotIn('private data', json.dumps(out))

    def test_depth_and_entry_limits_are_explicit(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve(); (root/'nested').mkdir(); (root/'nested'/'a.pdf').touch()
            out = inventory([str(root)], max_depth=0)
            self.assertEqual(out['roots'][0]['status'], 'partial')
            for i in range(10): (root/f'{i}.txt').touch()
            out = inventory([str(root), str(root/'nested')], max_entries=2)
            self.assertEqual(sum(r['entries_examined'] for r in out['roots']), 2)
            self.assertTrue(all(r['truncated'] for r in out['roots']))

    def test_denied_scan_is_not_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            with patch('discover_folders.os.scandir', side_effect=PermissionError('denied')):
                out = inventory([str(Path(tmp).resolve())])
            self.assertEqual(out['roots'][0]['status'], 'partial')
            self.assertTrue(out['roots'][0]['errors'])

    def test_symlink_root_and_ancestor_not_traversed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve(); (root/'real').mkdir(); (root/'real'/'nested').mkdir()
            (root/'alias').symlink_to(root/'real', target_is_directory=True)
            out = inventory([str(root/'alias'), str(root/'alias'/'nested')])
            self.assertEqual(out['roots'][0]['status'], 'symlink_skipped')
            self.assertEqual(out['roots'][1]['status'], 'symlink_ancestor_skipped')

    def test_macos_collectors_with_mock_os_not_live_workstation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            # Mock osascript and mount through PATH; all app/folder evidence is synthetic.
            (root/'osascript').write_text('#!/bin/sh\ncase "$2" in\n *"is running"*) echo false ;;\n *"System Events"*) echo "Excel, Unknown ERP" ;;\n *) echo /Volumes/Invoices/2026 ;;\nesac\n')
            (root/'mount').write_text('#!/bin/sh\necho "//user:secret@server/share on /custom/Invoices (smbfs, nodev)"\n')
            for p in root.iterdir(): p.chmod(0o755)
            env = dict(os.environ, PATH=str(root)+os.pathsep+os.environ['PATH'])
            p = subprocess.run(['bash', str(SCRIPTS/'inventory_macos.sh')], env=env, text=True, capture_output=True, check=True)
            out = json.loads(p.stdout)
            self.assertEqual(out['mounted_shares'][0]['device'], '//server/share')
            self.assertEqual(out['mounted_shares'][0]['mount_point'], '/custom/Invoices')
            self.assertEqual(out['open_folders'], ['/Volumes/Invoices/2026'])
            p = subprocess.run(['bash', str(SCRIPTS/'browser_tabs_macos.sh')], env=env, text=True, capture_output=True, check=True)
            self.assertEqual(json.loads(p.stdout)['browser_tabs'], [])


if __name__ == '__main__':
    unittest.main()
