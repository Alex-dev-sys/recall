#!/usr/bin/env python3
"""
Generate Fernet encryption key for Pyrogram sessions.
Run this script to get a secure encryption key.
"""

from cryptography.fernet import Fernet

if __name__ == "__main__":
    key = Fernet.generate_key().decode()
    print("=" * 60)
    print("GENERATED ENCRYPTION KEY FOR TELEGRAM SESSIONS")
    print("=" * 60)
    print()
    print("Copy this key to config/config.yaml:")
    print()
    print(f"telegram:")
    print(f"  session_encryption_key: \"{key}\"")
    print()
    print("=" * 60)
    print("⚠️  IMPORTANT: Keep this key secret!")
    print("=" * 60)
