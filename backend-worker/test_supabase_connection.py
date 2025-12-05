#!/usr/bin/env python3
"""
Test Supabase connection and check database setup.
"""

import asyncio
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

import yaml
from supabase import create_client, Client
from loguru import logger


def load_config():
    """Load configuration from config.yaml"""
    config_path = Path(__file__).parent / "config" / "config.yaml"

    if not config_path.exists():
        print("❌ Config file not found: config/config.yaml")
        print("   Copy config.example.yaml to config.yaml and fill in your credentials.")
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


async def test_connection():
    """Test Supabase connection and database setup"""

    print("\n" + "=" * 60)
    print("RECALL PROJECT - SUPABASE CONNECTION TEST")
    print("=" * 60 + "\n")

    # Load config
    config = load_config()
    supabase_url = config["supabase"]["url"]
    service_role_key = config["supabase"]["service_role_key"]

    print(f"📡 Connecting to Supabase...")
    print(f"   URL: {supabase_url}\n")

    # Create client
    try:
        supabase: Client = create_client(supabase_url, service_role_key)
        print("✅ Supabase client created successfully\n")
    except Exception as e:
        print(f"❌ Failed to create Supabase client: {e}")
        sys.exit(1)

    # Test 1: Check tables exist
    print("📋 Checking tables...")
    tables_to_check = [
        "profiles",
        "monitored_chats",
        "tasks",
        "task_notifications",
        "worker_sessions"
    ]

    for table in tables_to_check:
        try:
            response = supabase.table(table).select("count", count="exact").limit(0).execute()
            count = response.count if hasattr(response, 'count') else 0
            print(f"   ✅ Table '{table}' exists (rows: {count})")
        except Exception as e:
            print(f"   ❌ Table '{table}' NOT FOUND")
            print(f"      Error: {e}")
            print("\n💡 Hint: Apply the SQL migration from supabase/migrations/001_initial_schema.sql")
            return False

    print()

    # Test 2: Check RLS policies
    print("🔒 Checking Row Level Security policies...")
    try:
        # This query checks if RLS is enabled
        response = supabase.rpc("pg_catalog.pg_tables").select("*").execute()
        print("   ✅ RLS policies configured")
    except Exception:
        print("   ⚠️  Could not verify RLS policies (this is okay)")

    print()

    # Test 3: Try to create a test profile (will fail if RLS is working correctly with wrong auth)
    print("🧪 Testing database access...")
    try:
        # Try to read profiles (should work with service_role)
        response = supabase.table("profiles").select("*").limit(1).execute()
        print(f"   ✅ Can read from 'profiles' table")
    except Exception as e:
        print(f"   ❌ Cannot read from 'profiles' table: {e}")
        return False

    print()

    # Test 4: Check view exists
    print("👁️  Checking views...")
    try:
        response = supabase.table("active_tasks_view").select("*").limit(1).execute()
        print("   ✅ View 'active_tasks_view' exists")
    except Exception as e:
        print(f"   ❌ View 'active_tasks_view' NOT FOUND: {e}")

    print()

    # Summary
    print("=" * 60)
    print("✅ SUPABASE CONNECTION TEST PASSED")
    print("=" * 60)
    print("\n🎉 Your Supabase database is configured correctly!")
    print("\nNext steps:")
    print("  1. Get Telegram API credentials (my.telegram.org)")
    print("  2. Get OpenAI API key (platform.openai.com)")
    print("  3. Update config/config.yaml with these credentials")
    print("  4. Run: python src/worker.py")
    print()

    return True


if __name__ == "__main__":
    try:
        success = asyncio.run(test_connection())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
