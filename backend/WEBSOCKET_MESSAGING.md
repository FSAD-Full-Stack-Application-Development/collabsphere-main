# WebSocket Messaging System Documentation

## Overview
Real-time messaging system using ActionCable (WebSocket) with the following features:
- Real-time message delivery
- Typing indicators
- Read receipts
- Project-based and direct messaging

## Socket Namespace
**Endpoint:** `/cable`

### Connection
Connect to the WebSocket server with JWT authentication:

```javascript
// JavaScript/Frontend Example
const cable = ActionCable.createConsumer('ws://localhost:3000/cable?token=YOUR_JWT_TOKEN');
```

### Subscribe to Messages Channel

**Project Messages:**
```javascript
const subscription = cable.subscriptions.create(
  { channel: 'MessagesChannel', project_id: 'PROJECT_UUID' },
  {
    connected() {
      console.log('Connected to project messages');
    },
    received(data) {
      console.log('Received:', data);
      // Handle different events based on data.event
      switch(data.event) {
        case 'message:receive':
          // New message received
          break;
        case 'message:typing':
          // Someone is typing
          break;
        case 'message:read':
          // Message was read
          break;
      }
    }
  }
);
```

**Personal Messages:**
```javascript
const subscription = cable.subscriptions.create(
  { channel: 'MessagesChannel' }, // No project_id for personal messages
  {
    connected() {
      console.log('Connected to personal messages');
    },
    received(data) {
      console.log('Received:', data);
    }
  }
);
```

## Events

### 1. message:send
**Direction:** Client → Server  
**Action:** Send a new message

**Payload:**
```json
{
  "project_id": "uuid (optional)",
  "receiver_id": "uuid (required)",
  "content": "message text (required)"
}
```

**Frontend Example:**
```javascript
subscription.perform('send_message', {
  receiver_id: 'user-uuid-123',
  project_id: 'project-uuid-456', // optional
  content: 'Hello! How are you?'
});
```

**Response to Sender:**
```json
{
  "event": "message:sent",
  "message_id": "uuid",
  "timestamp": "2024-01-01T12:00:00Z",
  "status": "delivered"
}
```

---

### 2. message:receive
**Direction:** Server → Client (Receiver)  
**Action:** Real-time message delivery

**Payload:**
```json
{
  "event": "message:receive",
  "message_id": "uuid",
  "sender_id": "uuid",
  "sender_name": "John Doe",
  "receiver_id": "uuid",
  "project_id": "uuid or null",
  "content": "message text",
  "timestamp": "2024-01-01T12:00:00Z",
  "is_read": false
}
```

**Frontend Handling:**
```javascript
received(data) {
  if (data.event === 'message:receive') {
    // Display the message in UI
    displayMessage(data);
    // Optionally mark as read
    this.perform('mark_as_read', { message_id: data.message_id });
  }
}
```

---

### 3. message:typing
**Direction:** Client → Server → Other Client  
**Action:** Typing indicator

**Payload (Send):**
```json
{
  "project_id": "uuid (optional)",
  "receiver_id": "uuid (required)"
}
```

**Frontend Example (Throttled):**
```javascript
let typingTimeout;

function onUserTyping(receiverId, projectId = null) {
  clearTimeout(typingTimeout);
  
  subscription.perform('typing', {
    receiver_id: receiverId,
    project_id: projectId
  });
  
  // Stop sending after 3 seconds of no typing
  typingTimeout = setTimeout(() => {
    // User stopped typing
  }, 3000);
}
```

**Payload (Receive):**
```json
{
  "event": "message:typing",
  "sender_id": "uuid",
  "sender_name": "John Doe",
  "project_id": "uuid or null",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Frontend Handling:**
```javascript
received(data) {
  if (data.event === 'message:typing') {
    showTypingIndicator(data.sender_name);
    
    // Hide after 3 seconds
    setTimeout(() => {
      hideTypingIndicator(data.sender_id);
    }, 3000);
  }
}
```

---

### 4. message:read
**Direction:** Client → Server  
**Action:** Mark message as read

**Payload:**
```json
{
  "message_id": "uuid (required)"
}
```

**Frontend Example:**
```javascript
subscription.perform('mark_as_read', {
  message_id: 'message-uuid-123'
});
```

**Response to Reader:**
```json
{
  "event": "message:read_confirmed",
  "message_id": "uuid",
  "status": "read"
}
```

**Broadcast to Sender (Read Receipt):**
```json
{
  "event": "message:read",
  "message_id": "uuid",
  "read_by": "uuid",
  "read_at": "2024-01-01T12:00:00Z"
}
```

**Frontend Handling:**
```javascript
received(data) {
  if (data.event === 'message:read') {
    // Update UI to show message was read
    markMessageAsRead(data.message_id);
    showReadReceipt(data.read_at);
  }
}
```

---

## Complete Frontend Example

```javascript
class MessageManager {
  constructor(token, projectId = null) {
    this.token = token;
    this.projectId = projectId;
    this.cable = null;
    this.subscription = null;
    this.typingTimeout = null;
  }

  connect() {
    // Create WebSocket connection with JWT token
    this.cable = ActionCable.createConsumer(
      `ws://localhost:3000/cable?token=${this.token}`
    );

    // Subscribe to messages channel
    const params = { channel: 'MessagesChannel' };
    if (this.projectId) {
      params.project_id = this.projectId;
    }

    this.subscription = this.cable.subscriptions.create(params, {
      connected: () => {
        console.log(' Connected to messages channel');
      },

      disconnected: () => {
        console.log('❌ Disconnected from messages channel');
      },

      received: (data) => {
        this.handleIncomingData(data);
      }
    });
  }

  handleIncomingData(data) {
    switch(data.event) {
      case 'message:receive':
        this.onMessageReceived(data);
        break;
      case 'message:typing':
        this.onTypingIndicator(data);
        break;
      case 'message:read':
        this.onMessageRead(data);
        break;
      case 'message:sent':
        this.onMessageSent(data);
        break;
      case 'error':
        this.onError(data);
        break;
    }
  }

  sendMessage(receiverId, content) {
    this.subscription.perform('send_message', {
      receiver_id: receiverId,
      project_id: this.projectId,
      content: content
    });
  }

  sendTypingIndicator(receiverId) {
    clearTimeout(this.typingTimeout);
    
    this.subscription.perform('typing', {
      receiver_id: receiverId,
      project_id: this.projectId
    });

    this.typingTimeout = setTimeout(() => {
      // Typing stopped
    }, 3000);
  }

  markAsRead(messageId) {
    this.subscription.perform('mark_as_read', {
      message_id: messageId
    });
  }

  onMessageReceived(data) {
    console.log('📨 New message:', data);
    // Update UI with new message
    // Optionally auto-mark as read
    this.markAsRead(data.message_id);
  }

  onTypingIndicator(data) {
    console.log('✍️ Typing:', data.sender_name);
    // Show typing indicator in UI
  }

  onMessageRead(data) {
    console.log(' Message read:', data.message_id);
    // Update UI to show read receipt
  }

  onMessageSent(data) {
    console.log(' Message sent:', data.message_id);
    // Update UI to show message was delivered
  }

  onError(data) {
    console.error('❌ Error:', data.error);
    // Show error in UI
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    if (this.cable) {
      this.cable.disconnect();
    }
  }
}

// Usage Example
const token = 'your-jwt-token';
const projectId = 'project-uuid-123';

// Create manager
const messageManager = new MessageManager(token, projectId);

// Connect
messageManager.connect();

// Send a message
messageManager.sendMessage('receiver-uuid', 'Hello there!');

// Send typing indicator
messageManager.sendTypingIndicator('receiver-uuid');

// Disconnect when done
// messageManager.disconnect();
```

---

## Testing with wscat

Install wscat:
```bash
npm install -g wscat
```

Connect and test:
```bash
# Connect to WebSocket
wscat -c "ws://localhost:3000/cable?token=YOUR_JWT_TOKEN"

# Subscribe to channel
{"command":"subscribe","identifier":"{\"channel\":\"MessagesChannel\",\"project_id\":\"PROJECT_UUID\"}"}

# Send a message
{"command":"message","identifier":"{\"channel\":\"MessagesChannel\"}","data":"{\"action\":\"send_message\",\"receiver_id\":\"USER_UUID\",\"content\":\"Test message\"}"}

# Send typing indicator
{"command":"message","identifier":"{\"channel\":\"MessagesChannel\"}","data":"{\"action\":\"typing\",\"receiver_id\":\"USER_UUID\"}"}

# Mark as read
{"command":"message","identifier":"{\"channel\":\"MessagesChannel\"}","data":"{\"action\":\"mark_as_read\",\"message_id\":\"MESSAGE_UUID\"}"}
```

---

## Architecture

### Channels
- **Personal Channel:** `messages_user_#{user_id}` - Receives all messages for a specific user
- **Project Channel:** `messages_project_#{project_id}` - Receives all messages in a project context

### Flow

1. **Sending Messages:**
   - Client calls `send_message` action
   - Server creates Message record
   - Server broadcasts `message:receive` to receiver's channel
   - Server creates notification
   - Server confirms to sender with `message:sent`

2. **Typing Indicators:**
   - Client calls `typing` action
   - Server broadcasts `message:typing` to receiver's channel
   - No database persistence

3. **Read Receipts:**
   - Client calls `mark_as_read` action
   - Server updates Message record (is_read = true)
   - Server broadcasts `message:read` to sender's channel
   - Server confirms to reader with `message:read_confirmed`

### Security
- JWT authentication required for WebSocket connection
- Users can only access their own messages
- Receiver validation ensures messages go to correct user
- Authorization checks on mark_as_read action

---

## Database Schema

```ruby
create_table "messages", id: :uuid do |t|
  t.uuid "sender_id", null: false
  t.uuid "receiver_id", null: false
  t.uuid "project_id"  # Optional project context
  t.text "content"
  t.datetime "sent_at"
  t.boolean "is_read", default: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

---

## Error Handling

All errors are sent with:
```json
{
  "event": "error",
  "error": "Error message description"
}
```

Common errors:
- Missing required fields (receiver_id, content, message_id)
- Message not found or unauthorized
- Failed to save message
- Failed to mark as read

---

## Production Considerations

1. **Scaling:** Use Redis adapter for multi-server deployments
   ```ruby
   # config/cable.yml
   production:
     adapter: redis
     url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
   ```

2. **SSL:** Use `wss://` for secure WebSocket connections

3. **Rate Limiting:** Consider rate limiting on message sending

4. **Message History:** Use REST API to load historical messages

5. **Presence:** Track online/offline status separately

6. **Delivery Status:** Enhance with delivery confirmations

---

## Related Endpoints

### REST API for Message History

**GET /api/v1/messages**
- Query params: `project_id`, `user_id`, `page`, `per_page`
- Returns paginated message history

**GET /api/v1/messages/unread**
- Returns count and list of unread messages

**DELETE /api/v1/messages/:id**
- Delete a message (soft delete recommended)

---

## Notification Integration

When a message is sent, a notification is automatically created:
```ruby
NotificationService.message_received(message)
```

Notification type: `new_message`  
Contains: sender info, project info, message preview
