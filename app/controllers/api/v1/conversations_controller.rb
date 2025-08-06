class Api::V1::ConversationsController < Api::V1::BaseController
  def index
    # Get all users the current user has conversations with
    conversations = current_user.conversations
                               .includes(:avatar_attachment)
                               .map { |user| conversation_data(user) }
                               .sort_by { |conv| conv[:last_message_at] }
                               .reverse

    render_success({ conversations: conversations })
  end

  def show
    @receiver = User.find_by(username: params[:id]) # Using :id param for username
    unless @receiver
      return render_not_found("User not found")
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
        is_sender: message.sender == current_user,
        sender: {
          id: message.sender.id,
          username: message.sender.username,
          name: message.sender.name,
          avatar: message.sender.avatar.attached? ? message.sender.avatar.url : nil
        }
      }
    end.reverse # Reverse to show oldest first for chat display

    render_success({
      messages: messages_data,
      receiver: {
        id: @receiver.id,
        username: @receiver.username,
        name: @receiver.name,
        avatar: @receiver.avatar.attached? ? @receiver.avatar.url : nil
      },
      has_more: @messages.next_page.present?
    })
  end

  private

  def conversation_data(user)
    last_message = Message.between_users(current_user, user).last
    {
      user: {
        id: user.id,
        username: user.username,
        name: user.name,
        avatar: user.avatar.attached? ? user.avatar.url : nil
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

# app/controllers/api/v1/messages_controller.rb
class Api::V1::MessagesController < Api::V1::BaseController
  before_action :set_conversation

  def create
    @message = current_user.sent_messages.build(message_params)
    @message.receiver = @receiver

    if @message.save
      message_data = {
        id: @message.id,
        content: @message.content,
        created_at: @message.created_at,
        is_sender: true,
        sender: {
          id: current_user.id,
          username: current_user.username,
          name: current_user.name,
          avatar: current_user.avatar.attached? ? current_user.avatar.url : nil
        }
      }

      render_success(message_data, "Message sent successfully", :created)
    else
      render_error("Unable to send message", :unprocessable_entity, @message.errors.full_messages)
    end
  end

  private

  def set_conversation
    @receiver = User.find_by(username: params[:conversation_id])
    unless @receiver
      render_not_found("User not found")
    end
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
