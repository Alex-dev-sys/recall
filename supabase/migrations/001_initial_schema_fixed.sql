-- ==========================================
-- RECALL PROJECT - DATABASE SCHEMA (FIXED)
-- Safe to run multiple times
-- ==========================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- TABLE: profiles
-- ==========================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    telegram_user_id BIGINT UNIQUE,
    encrypted_session TEXT,
    onesignal_player_id TEXT,
    phone_number TEXT,
    first_name TEXT,
    last_name TEXT,
    username TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes (with IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_profiles_telegram_user_id ON public.profiles(telegram_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal_player_id ON public.profiles(onesignal_player_id) WHERE onesignal_player_id IS NOT NULL;

-- ==========================================
-- TABLE: monitored_chats
-- ==========================================
CREATE TABLE IF NOT EXISTS public.monitored_chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chat_id BIGINT NOT NULL,
    chat_title TEXT NOT NULL,
    chat_type TEXT CHECK (chat_type IN ('private', 'group', 'supergroup', 'channel')),
    is_active BOOLEAN DEFAULT true,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,
    UNIQUE(user_id, chat_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_monitored_chats_user_id ON public.monitored_chats(user_id);
CREATE INDEX IF NOT EXISTS idx_monitored_chats_chat_id ON public.monitored_chats(chat_id);
CREATE INDEX IF NOT EXISTS idx_monitored_chats_active ON public.monitored_chats(user_id, is_active) WHERE is_active = true;

-- ==========================================
-- TABLE: tasks
-- ==========================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chat_id BIGINT NOT NULL,
    message_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    original_quote TEXT NOT NULL,
    task_type TEXT CHECK (task_type IN ('request', 'promise', 'agreement', 'reminder')),
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'high', 'medium', 'low')) DEFAULT 'medium',
    deadline TIMESTAMPTZ,
    deadline_is_precise BOOLEAN DEFAULT false,
    status TEXT NOT NULL CHECK (status IN ('new', 'acknowledged', 'in_progress', 'done', 'cancelled')) DEFAULT 'new',
    source_link TEXT,
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
    is_duplicate BOOLEAN DEFAULT false,
    duplicate_of UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    ai_reasoning JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Add foreign key constraint only if it doesn't exist
DO $$ BEGIN
    ALTER TABLE public.tasks
    ADD CONSTRAINT tasks_chat_fk
    FOREIGN KEY (user_id, chat_id)
    REFERENCES public.monitored_chats(user_id, chat_id)
    ON DELETE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(user_id, status) WHERE status NOT IN ('done', 'cancelled');
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(user_id, priority, deadline);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON public.tasks(deadline) WHERE deadline IS NOT NULL AND status NOT IN ('done', 'cancelled');
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_chat_id ON public.tasks(chat_id, message_id);

-- ==========================================
-- TABLE: task_notifications
-- ==========================================
CREATE TABLE IF NOT EXISTS public.task_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    notification_type TEXT CHECK (notification_type IN ('creation', 'reminder', 'deadline_approaching', 'overdue')),
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    fcm_message_id TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_task_notifications_task_id ON public.task_notifications(task_id);

-- ==========================================
-- TABLE: worker_sessions
-- ==========================================
CREATE TABLE IF NOT EXISTS public.worker_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    worker_instance_id TEXT NOT NULL,
    status TEXT CHECK (status IN ('starting', 'running', 'stopping', 'stopped', 'error')) DEFAULT 'starting',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
    stopped_at TIMESTAMPTZ,
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_worker_sessions_user_id ON public.worker_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_worker_sessions_status ON public.worker_sessions(status) WHERE status IN ('running', 'error');

-- ==========================================
-- FUNCTIONS
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_task_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'done' AND OLD.status != 'done' THEN
        NEW.completed_at = NOW();
    ELSIF NEW.status != 'done' THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- TRIGGERS (Drop and recreate)
-- ==========================================

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON public.tasks;
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS task_completion_trigger ON public.tasks;
CREATE TRIGGER task_completion_trigger
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION set_task_completed_at();

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monitored_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

DROP POLICY IF EXISTS "Users can view own monitored chats" ON public.monitored_chats;
DROP POLICY IF EXISTS "Users can insert own monitored chats" ON public.monitored_chats;
DROP POLICY IF EXISTS "Users can update own monitored chats" ON public.monitored_chats;
DROP POLICY IF EXISTS "Users can delete own monitored chats" ON public.monitored_chats;

DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;

DROP POLICY IF EXISTS "Users can view own task notifications" ON public.task_notifications;
DROP POLICY IF EXISTS "Users can view own worker sessions" ON public.worker_sessions;

-- Create policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own monitored chats" ON public.monitored_chats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own monitored chats" ON public.monitored_chats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own monitored chats" ON public.monitored_chats
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own monitored chats" ON public.monitored_chats
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own tasks" ON public.tasks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks" ON public.tasks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks" ON public.tasks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks" ON public.tasks
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own task notifications" ON public.task_notifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.tasks
            WHERE tasks.id = task_notifications.task_id
            AND tasks.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view own worker sessions" ON public.worker_sessions
    FOR SELECT USING (auth.uid() = user_id);

-- ==========================================
-- GRANT PERMISSIONS
-- ==========================================

GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.monitored_chats TO service_role;
GRANT ALL ON public.tasks TO service_role;
GRANT ALL ON public.task_notifications TO service_role;
GRANT ALL ON public.worker_sessions TO service_role;

-- ==========================================
-- VIEWS
-- ==========================================

CREATE OR REPLACE VIEW public.active_tasks_view AS
SELECT
    t.*,
    mc.chat_title,
    mc.chat_type,
    CASE
        WHEN t.deadline IS NOT NULL AND t.deadline < NOW() THEN true
        ELSE false
    END as is_overdue,
    CASE
        WHEN t.deadline IS NOT NULL THEN EXTRACT(EPOCH FROM (t.deadline - NOW()))
        ELSE NULL
    END as seconds_until_deadline
FROM public.tasks t
JOIN public.monitored_chats mc ON t.chat_id = mc.chat_id AND t.user_id = mc.user_id
WHERE t.status NOT IN ('done', 'cancelled')
ORDER BY
    CASE t.priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END,
    t.deadline NULLS LAST,
    t.created_at DESC;

GRANT SELECT ON public.active_tasks_view TO authenticated;
GRANT SELECT ON public.active_tasks_view TO service_role;

-- ==========================================
-- COMMENTS
-- ==========================================

COMMENT ON TABLE public.profiles IS 'User profiles with Telegram session data';
COMMENT ON TABLE public.monitored_chats IS 'Chats that users want to monitor for tasks';
COMMENT ON TABLE public.tasks IS 'Extracted tasks from Telegram messages with AI analysis';
COMMENT ON TABLE public.task_notifications IS 'Log of sent push notifications';
COMMENT ON TABLE public.worker_sessions IS 'Active Pyrogram worker sessions for monitoring';
