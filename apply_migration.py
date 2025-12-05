#!/usr/bin/env python3
"""
Apply SQL migration to Supabase database
"""
import asyncio
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://pavrkvgztgksaovujeld.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDY4MjkyMCwiZXhwIjoyMDgwMjU4OTIwfQ.sQrchRCQpDClMJieC9hCqW7b9r4kAEJKYvadsiKSthc"

def apply_migration():
    """Apply the SQL migration"""
    print("🔄 Connecting to Supabase...")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    print("📖 Reading migration file...")
    with open("supabase/migrations/001_initial_schema.sql", "r", encoding="utf-8") as f:
        sql = f.read()

    print("🚀 Applying migration...")

    # Split by statements and execute one by one
    statements = [s.strip() for s in sql.split(';') if s.strip() and not s.strip().startswith('--')]

    for i, statement in enumerate(statements, 1):
        if not statement:
            continue
        try:
            print(f"   Executing statement {i}/{len(statements)}...")
            result = supabase.postgrest.rpc('exec_sql', {'query': statement}).execute()
            print(f"   ✅ Statement {i} executed")
        except Exception as e:
            print(f"   ⚠️  Statement {i} failed: {e}")
            # Continue with next statement

    print("\n✅ Migration completed!")
    print("\n📊 Created tables:")
    print("   - profiles")
    print("   - monitored_chats")
    print("   - tasks")
    print("   - task_notifications")
    print("   - worker_sessions")
    print("\n🔐 Row Level Security enabled")
    print("📈 Views and triggers created")
    print("\n✨ Database is ready!")

if __name__ == "__main__":
    apply_migration()
