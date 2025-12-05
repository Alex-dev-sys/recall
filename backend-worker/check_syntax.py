#!/usr/bin/env python3
"""
Check Python syntax for all source files
"""
import py_compile
import sys
from pathlib import Path

def check_file(filepath):
    """Check syntax of a single file"""
    try:
        py_compile.compile(filepath, doraise=True)
        print(f"✅ {filepath.name}")
        return True
    except py_compile.PyCompileError as e:
        print(f"❌ {filepath.name}: {e}")
        return False

def main():
    src_dir = Path(__file__).parent / "src"

    if not src_dir.exists():
        print("❌ src directory not found!")
        return False

    print("🔍 Checking Python syntax...\n")

    py_files = list(src_dir.glob("*.py"))

    if not py_files:
        print("❌ No Python files found!")
        return False

    results = []
    for py_file in sorted(py_files):
        result = check_file(py_file)
        results.append(result)

    print(f"\n{'='*50}")
    passed = sum(results)
    total = len(results)

    if passed == total:
        print(f"✅ All {total} files passed syntax check!")
        return True
    else:
        print(f"❌ {total - passed}/{total} files have syntax errors")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
