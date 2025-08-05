class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_receiver, only: [ :show, :create ]

  def index
    @conversations = current_user.conversations
                                .includes(:avatar_attachment)
                                .map { |user| conversation_data(user) }
                                .sort_by { |conv| conv[:last_message_at] }
                                .reverse
  end

  def show
    @conversation_id = [ @receiver.id, current_user.id ].sort.join("_")
    @messages = current_user.conversation_with(@receiver)
                           .includes(:sender)
                           .order(:created_at)

    # Mark messages as read
    mark_messages_as_read

    @message = Message.new
  end

  def create
    @message = current_user.sent_messages.build(message_params)
    @message.receiver = @receiver

    respond_to do |format|
      if @message.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("message_form", partial: "messages/message_form",
                                locals: { message: Message.new, receiver: @receiver })
          ]
        end
        format.html { redirect_to conversation_path(@receiver.username) }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("message_form",
                                                   partial: "messages/message_form",
                                                   locals: { message: @message, receiver: @receiver })
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  def mark_as_read
    message = Message.find(params[:id])
    if message.receiver == current_user
      message.mark_as_read!
      head :ok
    else
      head :forbidden
    end
  end

  private

  def set_receiver
    @receiver = User.find_by(username: params[:username])
    unless @receiver
      redirect_to messages_path, alert: "User not found"
    end
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def conversation_data(user)
    last_message = Message.between_users(current_user, user).last
    {
      user: user,
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

  def can_message_user?(user)
    return false if user.banned? && !current_user.admin?
    return false if current_user.banned?
    true
  end
end
