import asyncio
from supabase import create_client, Client

# Hardcoded credentials to verify quickly (since verify_db might run in env where config load is tricky)
# But ideally should read from config. Let's try reading from config first or fallback.
# Actually, let's just use the known credentials since we just wrote them.
URL = "https://pavrkvgztgksaovujeld.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDY4MjkyMCwiZXhwIjoyMDgwMjU4OTIwfQ.sQrchRCQpDClMJieC9hCqW7b9r4kAEJKYvadsiKSthc"

def verify():
    print("Connecting to Supabase...")
    try:
        sb = create_client(URL, KEY)
        print("Checking 'profiles' table...")
        # Try to select 1 row
        res = sb.table("profiles").select("id").limit(1).execute()
        print("Success! Database connection working.")
        print(f"Profiles count query result: {res}")
    except Exception as e:
        print(f"Error connecting: {e}")

if __name__ == "__main__":
    verify()
