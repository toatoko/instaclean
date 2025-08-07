class Api::V1::MessagesController < Api::V1::BaseController
  before_action :set_conversation

  def create
    # Check if users can message each other
    if current_user.mutually_blocked?(@receiver) || @receiver.banned?
      return render_error("Cannot send message to this user", :forbidden)
    end

    @message = current_user.sent_messages.build(message_params)
    @message.receiver = @receiver

    if @message.save
      message_data = {
        id: @message.id,
        content: @message.content,
        created_at: @message.created_at,
        read_at: @message.read_at,
        is_sender: true,
        sender: {
          id: current_user.id,
          username: current_user.username,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          full_name: current_user.full_name,
          avatar: current_user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(current_user.avatar, only_path: false) : nil
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
