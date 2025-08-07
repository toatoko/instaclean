class Api::V1::ConversationsController < Api::V1::BaseController
  def index
    # Get all conversations - this is different from user management
    conversations = current_user.conversations
                               .includes(:avatar_attachment)
                               .map { |user| conversation_data(user) }
                               .sort_by { |conv| conv[:last_message_at] }
                               .reverse

    render_success({
      conversations: conversations,
      total_unread: current_user.unread_messages_count
    })
  end

  def show
    @receiver = User.find_by(username: params[:id])
    unless @receiver
      return render_not_found("User not found")
    end

    # Check if users can message each other
    if current_user.mutually_blocked?(@receiver) || @receiver.banned?
      return render_error("Cannot access this conversation", :forbidden)
    end

    @messages = current_user.conversation_with(@receiver)
                           .includes(:sender, sender: [ :avatar_attachment ])
                           .order(created_at: :desc)
                           .page(params[:page]).per(50)

    # Mark messages as read
    mark_messages_as_read

    messages_data = @messages.map do |message|
      {
        id: message.id,
        content: message.content,
        created_at: message.created_at,
        read_at: message.read_at,
        is_sender: message.sender == current_user,
        sender: {
          id: message.sender.id,
          username: message.sender.username,
          first_name: message.sender.first_name,
          last_name: message.sender.last_name,
          full_name: message.sender.full_name,
          avatar: message.sender.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(message.sender.avatar, only_path: false) : nil
        }
      }
    end.reverse # Reverse to show oldest first for chat display

    render_success({
      messages: messages_data,
      receiver: {
        id: @receiver.id,
        username: @receiver.username,
        first_name: @receiver.first_name,
        last_name: @receiver.last_name,
        full_name: @receiver.full_name,
        avatar: @receiver.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(@receiver.avatar, only_path: false) : nil
      },
      has_more: @messages.next_page.present?
    })
  end

  private

  def conversation_data(user)
    last_message = current_user.last_message_with(user)
    {
      user: {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil
      },
      last_message: last_message&.content,
      last_message_at: last_message&.created_at || Time.current,
      unread_count: current_user.unread_messages_from(user),
      is_sender: last_message&.sender == current_user
    }
  end

  def mark_messages_as_read
    current_user.received_messages
                .where(sender: @receiver, read_at: nil)
                .update_all(read_at: Time.current)
  end
end
