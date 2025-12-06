import yaml

config = {
    "supabase": {
        "url": "https://pavrkvgztgksaovujeld.supabase.co",
        "service_role_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDY4MjkyMCwiZXhwIjoyMDgwMjU4OTIwfQ.sQrchRCQpDClMJieC9hCqW7b9r4kAEJKYvadsiKSthc",
        "anon_key": "your-anon-key-here"
    },
    "telegram": {
        "api_id": 33483060,
        "api_hash": "d1342fc16e719ef2072012096a0b1a64",
        "session_encryption_key": "MAwc-8rGaRHYqz-P-Hgwg43CemX1Lnfc64tChWaaTBo="
    },
    "ai": {
        "provider": "openai",
        "model": "gpt-4o-mini",
        "api_key": "uFh6FnpT2PCEuvEgppEIPKDRmHQQnrS-XRLsuXp_IlY",
        "base_url": "https://api.gptlama.ru/v1",
        "max_retries": 3,
        "timeout": 30
    },
    "worker": {
        "poll_interval": 1,
        "heartbeat_interval": 30,
        "max_concurrent_users": 10,
        "log_level": "INFO"
    },
    "pipeline": {
        "min_confidence_threshold": 0.6,
        "duplicate_similarity_threshold": 0.85,
        "max_tasks_for_dedup_check": 50,
        "dedup_hours_back": 72,
        "enable_semantic_search": True
    },
    "notifications": {
        "enable_immediate": True,
        "enable_reminders": True,
        "reminder_intervals": [1440, 60, 15]
    },
    "logging": {
        "level": "INFO",
        "file": "logs/recall_worker.log",
        "max_size_mb": 100,
        "backup_count": 5,
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    }
}

with open("config/config.yaml", "w") as f:
    yaml.dump(config, f, sort_keys=False)

print("✅ config/config.yaml updated successfully")
