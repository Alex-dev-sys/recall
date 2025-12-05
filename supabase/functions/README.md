# Supabase Edge Functions

## Setup

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link to your project

```bash
supabase link --project-ref your-project-ref
```

### 4. Set environment variables

Create a `.env` file in the `supabase` directory:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
FCM_SERVER_KEY=your-fcm-server-key
```

Or set secrets via CLI:

```bash
supabase secrets set FCM_SERVER_KEY=your-fcm-server-key
```

### 5. Deploy the function

```bash
supabase functions deploy send-task-notification
```

## Setting up Database Webhook

To trigger the Edge Function when a new task is created, set up a Database Webhook:

1. Go to your Supabase project dashboard
2. Navigate to **Database > Webhooks**
3. Click **Create a new hook**
4. Configure:
   - **Name**: `task-notification-trigger`
   - **Table**: `tasks`
   - **Events**: `INSERT`
   - **Type**: `HTTP Request`
   - **Method**: `POST`
   - **URL**: `https://your-project.supabase.co/functions/v1/send-task-notification`
   - **Headers**:
     ```
     Authorization: Bearer YOUR_ANON_KEY
     Content-Type: application/json
     ```

5. Click **Create webhook**

## Firebase Cloud Messaging Setup

### Get FCM Server Key

#### Option 1: Legacy Server Key (Simple, but deprecated)

1. Go to Firebase Console
2. Select your project
3. Go to **Project Settings > Cloud Messaging**
4. Copy the **Server key**

#### Option 2: FCM v1 API (Recommended)

1. Go to Firebase Console > **Project Settings > Service Accounts**
2. Click **Generate new private key**
3. Download the JSON file
4. Use the private key to generate OAuth 2.0 tokens

For simplicity, the code uses legacy server key format. For production, migrate to FCM v1 API.

### Update the Edge Function

In `index.ts`, update the FCM endpoint:

```typescript
// For v1 API
const fcmUrl = "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send";

// For legacy API
const fcmUrl = "https://fcm.googleapis.com/fcm/send";
```

## Testing the Function

### Test locally

```bash
supabase functions serve send-task-notification --env-file supabase/.env
```

### Send a test request

```bash
curl -X POST http://localhost:54321/functions/v1/send-task-notification \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "tasks",
    "record": {
      "id": "test-uuid",
      "user_id": "user-uuid",
      "content": "Test task",
      "priority": "urgent",
      "deadline": "2024-12-03T15:00:00Z",
      "source_link": "https://t.me/c/123/456",
      "created_at": "2024-12-02T14:00:00Z"
    }
  }'
```

## Monitoring

View function logs:

```bash
supabase functions logs send-task-notification
```

Or in the Supabase dashboard: **Edge Functions > send-task-notification > Logs**

## Troubleshooting

### Webhook not triggering

1. Check webhook is enabled in Supabase dashboard
2. Verify the webhook URL is correct
3. Check Edge Function logs for errors

### FCM errors

- **Invalid registration token**: User's FCM token is invalid or expired. Update the token.
- **Unauthorized**: Check your FCM server key is correct
- **Not found**: For v1 API, verify project ID is correct

### No notifications received

1. Verify FCM token is saved in the `profiles` table
2. Check Flutter app has proper Firebase configuration
3. Test FCM token using Firebase Console > Cloud Messaging > Send test message
