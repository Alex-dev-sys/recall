/**
 * Supabase Edge Function: Send Task Notification
 *
 * Triggered by Database Webhook on INSERT to tasks table.
 * Sends push notifications via OneSignal (no Firebase needed).
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

// Types
interface Task {
  id: string;
  user_id: string;
  content: string;
  priority: "urgent" | "high" | "medium" | "low";
  deadline: string | null;
  source_link: string;
  created_at: string;
}

interface Profile {
  onesignal_player_id: string | null;
  first_name: string | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Task;
  schema: string;
  old_record: Task | null;
}

interface OneSignalNotification {
  include_player_ids: string[];
  headings: { en: string; ru: string };
  contents: { en: string; ru: string };
  data: {
    task_id: string;
    priority: string;
    source_link: string;
    type: string;
  };
  priority?: number;
  android_channel_id?: string;
  ios_sound?: string;
  android_sound?: string;
}

// Environment variables
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID")!;
const ONESIGNAL_API_KEY = Deno.env.get("ONESIGNAL_API_KEY")!;

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Get OneSignal Player ID for user
 */
async function getOneSignalPlayerId(userId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("onesignal_player_id, first_name")
    .eq("id", userId)
    .single();

  if (error) {
    console.error("Failed to get OneSignal Player ID:", error);
    return null;
  }

  return (data as Profile).onesignal_player_id;
}

/**
 * Format notification message based on priority
 */
function formatNotification(task: Task): { title: string; body: string } {
  const priorityEmoji: Record<string, string> = {
    urgent: "🔴",
    high: "🟡",
    medium: "🔵",
    low: "⚪",
  };

  const emoji = priorityEmoji[task.priority] || "📋";

  let title: string;

  if (task.priority === "urgent") {
    title = `${emoji} СРОЧНАЯ ЗАДАЧА`;
  } else if (task.priority === "high") {
    title = `${emoji} Важная задача`;
  } else {
    title = `${emoji} Новая задача`;
  }

  let body = task.content;

  // Add deadline info if present
  if (task.deadline) {
    const deadline = new Date(task.deadline);
    const now = new Date();
    const hoursUntil = (deadline.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (hoursUntil < 2) {
      body += " ⏰ Через " + Math.round(hoursUntil * 60) + " минут";
    } else if (hoursUntil < 24) {
      body += " ⏰ Через " + Math.round(hoursUntil) + " часов";
    } else {
      body += " 📅 " + deadline.toLocaleDateString("ru-RU", {
        day: "numeric",
        month: "short",
        hour: "2-digit",
        minute: "2-digit",
      });
    }
  }

  return { title, body };
}

/**
 * Send push notification via OneSignal
 */
async function sendOneSignalNotification(
  playerId: string,
  task: Task
): Promise<{ success: boolean; notificationId?: string; error?: string }> {
  const { title, body } = formatNotification(task);

  // Construct OneSignal notification
  const notification: OneSignalNotification = {
    include_player_ids: [playerId],
    headings: {
      en: title,
      ru: title,
    },
    contents: {
      en: body,
      ru: body,
    },
    data: {
      task_id: task.id,
      priority: task.priority,
      source_link: task.source_link,
      type: "task_created",
    },
    priority: task.priority === "urgent" ? 10 : 5,
    android_channel_id: "task_notifications",
    ios_sound: task.priority === "urgent" ? "urgent.caf" : "default",
    android_sound: task.priority === "urgent" ? "urgent" : "default",
  };

  try {
    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        ...notification,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("OneSignal error:", result);
      return {
        success: false,
        error: result.errors?.join(", ") || "Unknown OneSignal error",
      };
    }

    console.log("Push notification sent:", result.id);

    return {
      success: true,
      notificationId: result.id,
    };
  } catch (error) {
    console.error("Failed to send OneSignal notification:", error);
    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Log notification to database
 */
async function logNotification(
  taskId: string,
  notificationType: string,
  success: boolean,
  notificationId?: string,
  errorMessage?: string
) {
  try {
    await supabase.from("task_notifications").insert({
      task_id: taskId,
      notification_type: notificationType,
      success,
      notification_id: notificationId,
      error_message: errorMessage,
    });
  } catch (error) {
    console.error("Failed to log notification:", error);
  }
}

/**
 * Main handler
 */
serve(async (req) => {
  try {
    // Verify webhook signature (recommended for production)
    // const signature = req.headers.get("x-supabase-signature");
    // if (!verifySignature(signature, req.body)) {
    //   return new Response("Unauthorized", { status: 401 });
    // }

    // Parse webhook payload
    const payload: WebhookPayload = await req.json();

    console.log("Received webhook:", payload.type, payload.table);

    // Only process INSERT events on tasks table
    if (payload.type !== "INSERT" || payload.table !== "tasks") {
      return new Response(
        JSON.stringify({ message: "Event ignored" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const task = payload.record;

    console.log(`Processing new task: ${task.id} - ${task.content}`);

    // Get OneSignal Player ID
    const playerId = await getOneSignalPlayerId(task.user_id);

    if (!playerId) {
      console.warn(`No OneSignal Player ID found for user ${task.user_id}`);
      await logNotification(
        task.id,
        "creation",
        false,
        undefined,
        "No OneSignal Player ID"
      );

      return new Response(
        JSON.stringify({ message: "No OneSignal Player ID found" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Send push notification
    const result = await sendOneSignalNotification(playerId, task);

    // Log notification
    await logNotification(
      task.id,
      "creation",
      result.success,
      result.notificationId,
      result.error
    );

    if (result.success) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Notification sent",
          notificationId: result.notificationId,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } else {
      return new Response(
        JSON.stringify({
          success: false,
          error: result.error,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Handler error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
