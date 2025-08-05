class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :content, presence: true, length: { maximum: 1000 }
  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  validate :sender_cannot_message_themselves

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :between_users, ->(user1, user2) {
    where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    )
  }

  # Turbo Streams for real-time updates
  after_create_commit :broadcast_message
  after_update_commit :broadcast_message_update

  def mark_as_read!
    update(read_at: Time.current) unless read?
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def conversation_id
    [ sender_id, receiver_id ].sort.join("_")
  end

  private

  def sender_cannot_message_themselves
    errors.add(:receiver, "can't message yourself") if sender_id == receiver_id
  end

  def broadcast_message
    # Broadcast to both users in the conversation
    broadcast_append_to "conversation_#{conversation_id}",
                        target: "messages",
                        partial: "messages/message",
                        locals: { message: self, current_user: sender }

    # Update conversation list for both users
    broadcast_replace_to "user_conversations_#{sender_id}",
                         target: "conversation_#{receiver_id}",
                         partial: "messages/conversation_item",
                         locals: { user: receiver, current_user: sender }

    broadcast_replace_to "user_conversations_#{receiver_id}",
                         target: "conversation_#{sender_id}",
                         partial: "messages/conversation_item",
                         locals: { user: sender, current_user: receiver }
  end

  def broadcast_message_update
    # Broadcast read status updates
    broadcast_replace_to "conversation_#{conversation_id}",
                         target: "message_#{id}",
                         partial: "messages/message",
                         locals: { message: self, current_user: sender }
  end
end
