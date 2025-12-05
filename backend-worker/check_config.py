#!/usr/bin/env python3
"""
Validate config.yaml
"""
import yaml
import sys
from pathlib import Path

def check_config():
    """Check config.yaml for errors"""
    config_path = Path(__file__).parent / "config" / "config.yaml"

    print("🔍 Checking config.yaml...\n")

    if not config_path.exists():
        print(f"❌ Config file not found: {config_path}")
        return False

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)

        print("✅ YAML syntax is valid\n")

        # Check required sections
        required_sections = ['supabase', 'telegram', 'ai', 'worker', 'pipeline']
        missing = []

        for section in required_sections:
            if section not in config:
                missing.append(section)
                print(f"❌ Missing section: {section}")
            else:
                print(f"✅ Found section: {section}")

        if missing:
            return False

        print("\n📋 Configuration values:\n")

        # Check Supabase
        print("Supabase:")
        print(f"  URL: {config['supabase']['url']}")
        print(f"  Service Key: {'✅ Set' if config['supabase']['service_role_key'] else '❌ Missing'}")

        # Check Telegram
        print("\nTelegram:")
        api_id = config['telegram']['api_id']
        api_hash = config['telegram']['api_hash']
        enc_key = config['telegram']['session_encryption_key']

        if api_id == 12345678:
            print(f"  api_id: ⚠️  Using default value - NEED TO UPDATE!")
        else:
            print(f"  api_id: ✅ {api_id}")

        if api_hash == "your-api-hash-here":
            print(f"  api_hash: ⚠️  Using default value - NEED TO UPDATE!")
        else:
            print(f"  api_hash: ✅ Set ({len(api_hash)} chars)")

        if "xK9mQ7nP5wR2tY" in enc_key:
            print(f"  encryption_key: ✅ Generated")
        else:
            print(f"  encryption_key: ⚠️  May need to regenerate")

        # Check AI
        print("\nAI API:")
        print(f"  Provider: {config['ai']['provider']}")
        print(f"  Model: {config['ai']['model']}")
        print(f"  API Key: {'✅ Set' if config['ai']['api_key'] else '❌ Missing'}")
        if 'base_url' in config['ai']:
            print(f"  Base URL: {config['ai']['base_url']}")

        # Check if Telegram API needs update
        needs_telegram = (
            api_id == 12345678 or
            api_hash == "your-api-hash-here"
        )

        print(f"\n{'='*50}")

        if needs_telegram:
            print("⚠️  ACTION REQUIRED:")
            print("   Get Telegram API credentials at: https://my.telegram.org")
            print("   Update config.yaml with your api_id and api_hash")
            return False
        else:
            print("✅ Configuration looks good!")
            print("   Ready to start worker!")
            return True

    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = check_config()
    sys.exit(0 if success else 1)
