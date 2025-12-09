#!/usr/bin/env python3
"""
Fix FFmpeg pkgconfig files after copying libraries to a new location.
Automatically updates all .pc files to point to the new installation directory.

Usage:
    python3 fix_ffmpeg_pkgconfig.py /path/to/ffmpeg
    python3 fix_ffmpeg_pkgconfig.py  # Uses $HOME/ffmpeg by default
"""

import sys
import re
from pathlib import Path


def fix_pkgconfig_files(ffmpeg_root: Path, dry_run: bool = False):
    """
    Fix all .pc files in ffmpeg_root/lib/pkgconfig to use the correct prefix.
    
    Args:
        ffmpeg_root: Root directory of FFmpeg installation
        dry_run: If True, only show what would be changed without modifying files
    """
    pkgconfig_dir = ffmpeg_root / "lib" / "pkgconfig"
    
    if not pkgconfig_dir.exists():
        print(f"❌ Error: pkgconfig directory not found at {pkgconfig_dir}")
        return False
    
    pc_files = list(pkgconfig_dir.glob("*.pc"))
    if not pc_files:
        print(f"❌ Error: No .pc files found in {pkgconfig_dir}")
        return False
    
    print(f"📂 FFmpeg root: {ffmpeg_root}")
    print(f"📁 Processing {len(pc_files)} .pc files in {pkgconfig_dir}")
    print()
    
    new_prefix = str(ffmpeg_root)
    modified_count = 0
    
    for pc_file in sorted(pc_files):
        print(f"📄 Processing: {pc_file.name}")
        
        try:
            content = pc_file.read_text()
            original_content = content
            
            # Find all unique prefix paths in the file
            old_prefixes = set()
            for line in content.splitlines():
                if line.startswith('prefix='):
                    match = re.match(r'prefix=(.+)', line)
                    if match:
                        old_prefix = match.group(1).strip()
                        if old_prefix != new_prefix:
                            old_prefixes.add(old_prefix)
            
            if not old_prefixes:
                print(f"  ✅ Already correct (prefix={new_prefix})")
                print()
                continue
            
            # Replace all old prefixes with new prefix
            for old_prefix in old_prefixes:
                print(f"  🔄 Replacing: {old_prefix}")
                print(f"            → {new_prefix}")
                # Use word boundaries to avoid partial replacements
                content = content.replace(old_prefix, new_prefix)
            
            if content != original_content:
                if dry_run:
                    print(f"  🔍 [DRY RUN] Would modify {pc_file.name}")
                else:
                    pc_file.write_text(content)
                    print(f"  ✅ Modified successfully")
                modified_count += 1
            
            print()
            
        except Exception as e:
            print(f"  ❌ Error processing {pc_file.name}: {e}")
            print()
    
    print("=" * 60)
    if dry_run:
        print(f"🔍 [DRY RUN] Would modify {modified_count} file(s)")
    else:
        print(f"✅ Successfully modified {modified_count} file(s)")
    print(f"✅ {len(pc_files) - modified_count} file(s) already correct")
    
    return True


def verify_pkgconfig_files(ffmpeg_root: Path):
    """Verify all .pc files point to the correct location."""
    pkgconfig_dir = ffmpeg_root / "lib" / "pkgconfig"
    pc_files = list(pkgconfig_dir.glob("*.pc"))
    
    print("\n" + "=" * 60)
    print("🔍 Verification:")
    print("=" * 60)
    
    new_prefix = str(ffmpeg_root)
    all_correct = True
    
    for pc_file in sorted(pc_files):
        content = pc_file.read_text()
        for line in content.splitlines():
            if line.startswith('prefix='):
                match = re.match(r'prefix=(.+)', line)
                if match:
                    prefix = match.group(1).strip()
                    if prefix == new_prefix:
                        print(f"✅ {pc_file.name}: {prefix}")
                    else:
                        print(f"❌ {pc_file.name}: {prefix} (should be {new_prefix})")
                        all_correct = False
                break
    
    print()
    if all_correct:
        print("✅ All pkgconfig files are correct!")
    else:
        print("❌ Some pkgconfig files still have incorrect paths")
    
    return all_correct


def main():
    # Parse arguments
    if len(sys.argv) > 1:
        if sys.argv[1] in ['-h', '--help']:
            print(__doc__)
            sys.exit(0)
        ffmpeg_root = Path(sys.argv[1]).expanduser().resolve()
    else:
        ffmpeg_root = Path.home() / "ffmpeg"
    
    # Check dry-run mode
    dry_run = '--dry-run' in sys.argv or '-n' in sys.argv
    
    if not ffmpeg_root.exists():
        print(f"❌ Error: FFmpeg directory not found at {ffmpeg_root}")
        print(f"\nUsage: {sys.argv[0]} [ffmpeg_path]")
        sys.exit(1)
    
    if dry_run:
        print("🔍 Running in DRY RUN mode (no files will be modified)")
        print()
    
    # Fix pkgconfig files
    success = fix_pkgconfig_files(ffmpeg_root, dry_run)
    
    if not success:
        sys.exit(1)
    
    # Verify if not dry-run
    if not dry_run:
        verify_pkgconfig_files(ffmpeg_root)


if __name__ == "__main__":
    main()
