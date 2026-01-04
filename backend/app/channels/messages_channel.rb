class MessagesChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to this channel
  def subscribed
    # Subscribe to a specific project's messages or user's direct messages
    if params[:project_id].present?
      stream_from "messages_project_#{params[:project_id]}"
      logger.info "User #{current_user.id} subscribed to project #{params[:project_id]} messages"
    else
      # Subscribe to user's personal messages across all projects
      stream_from "messages_user_#{current_user.id}"
      logger.info "User #{current_user.id} subscribed to personal messages"
    end
  end

  # Called when the consumer has cut the cable connection
  def unsubscribed
    stop_all_streams
  end

  # Handle message:send event
  # Payload: { project_id, receiver_id, content }
  def send_message(data)
    project_id = data['project_id']
    receiver_id = data['receiver_id']
    content = data['content']

    # Validate required fields
    unless receiver_id.present? && content.present?
      transmit({ 
        error: 'Missing required fields: receiver_id and content are required',
        event: 'error'
      })
      return
    end

    # Create the message
    message = Message.new(
      sender_id: current_user.id,
      receiver_id: receiver_id,
      project_id: project_id,
      content: content,
      sent_at: Time.current,
      is_read: false
    )

    if message.save
      # Broadcast to receiver - message:receive event
      broadcast_message_receive(message)
      
      # Create notification for receiver
      NotificationService.message_received(message)
      
      # Send confirmation to sender
      transmit({
        event: 'message:sent',
        message_id: message.id,
        timestamp: message.sent_at,
        status: 'delivered'
      })
      
      logger.info "Message #{message.id} sent from #{current_user.id} to #{receiver_id}"
    else
      transmit({ 
        error: message.errors.full_messages.join(', '),
        event: 'error'
      })
    end
  end

  # Handle message:typing event
  # Payload: { project_id, receiver_id }
  def typing(data)
    receiver_id = data['receiver_id']
    project_id = data['project_id']

    return unless receiver_id.present?

    # Broadcast typing indicator to the receiver
    typing_data = {
      event: 'message:typing',
      sender_id: current_user.id,
      sender_name: current_user.full_name,
      project_id: project_id,
      timestamp: Time.current
    }

    # Send to specific user
    ActionCable.server.broadcast(
      "messages_user_#{receiver_id}",
      typing_data
    )

    # If in project context, also broadcast to project channel
    if project_id.present?
      ActionCable.server.broadcast(
        "messages_project_#{project_id}",
        typing_data
      )
    end
  end

  # Handle message:read event
  # Payload: { message_id }
  def mark_as_read(data)
    message_id = data['message_id']

    unless message_id.present?
      transmit({ 
        error: 'Missing required field: message_id',
        event: 'error'
      })
      return
    end

    message = Message.find_by(id: message_id, receiver_id: current_user.id)

    unless message
      transmit({ 
        error: 'Message not found or unauthorized',
        event: 'error'
      })
      return
    end

    if message.update(is_read: true)
      # Broadcast read status to sender
      read_receipt_data = {
        event: 'message:read',
        message_id: message.id,
        read_by: current_user.id,
        read_at: Time.current
      }

      ActionCable.server.broadcast(
        "messages_user_#{message.sender_id}",
        read_receipt_data
      )

      # Confirm to current user
      transmit({
        event: 'message:read_confirmed',
        message_id: message.id,
        status: 'read'
      })
      
      logger.info "Message #{message.id} marked as read by #{current_user.id}"
    else
      transmit({ 
        error: 'Failed to mark message as read',
        event: 'error'
      })
    end
  end

  private

  # Broadcast message:receive event to the receiver
  def broadcast_message_receive(message)
    receive_data = {
      event: 'message:receive',
      message_id: message.id,
      sender_id: message.sender_id,
      sender_name: message.sender.full_name,
      receiver_id: message.receiver_id,
      project_id: message.project_id,
      content: message.content,
      timestamp: message.sent_at,
      is_read: message.is_read
    }

    # Send to receiver's personal channel
    ActionCable.server.broadcast(
      "messages_user_#{message.receiver_id}",
      receive_data
    )

    # If message is project-related, also broadcast to project channel
    if message.project_id.present?
      ActionCable.server.broadcast(
        "messages_project_#{message.project_id}",
        receive_data
      )
    end
  end
end
