class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # adding authentication_keys: [ :login ] for sigin user :login form instead of original :email form of devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,  authentication_keys: [ :login ]
  attr_writer :login
  has_one_attached :avatar
  validates :username, uniqueness: { case_sensitive: false }
  validates :avatar, presence: true

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  # USER BLOCKING ASSOCIATIONS (peer-to-peer blocking)
  has_many :blocking_relationships, class_name: "Block", foreign_key: "blocker_id", dependent: :destroy
  has_many :blocked_relationships, class_name: "Block", foreign_key: "blocked_id", dependent: :destroy
  has_many :blocked_users, through: :blocking_relationships, source: :blocked
  has_many :blocked_by_users, through: :blocked_relationships, source: :blocker

  # Message associations
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: "receiver_id", dependent: :destroy

  # Report associations
  has_many :reports_about_me, as: :reportable, class_name: "Report", dependent: :destroy
  has_many :submitted_reports, class_name: "Report", foreign_key: "reporter_id", dependent: :destroy
  has_many :resolved_reports, class_name: "Report", foreign_key: "resolved_by_id", dependent: :nullify

  # ADMIN BAN ASSOCIATIONS (site-wide bans)
  belongs_to :banned_by, class_name: "User", optional: true
  has_many :banned_users, class_name: "User", foreign_key: "banned_by_id"

  # Notification
  has_many :notifications, as: :recipient, dependent: :destroy

  # OPTIMIZED SCOPES
  scope :banned, -> { where.not(banned_at: nil) }
  scope :active, -> { where(banned_at: nil) }
  scope :admins, -> { where(admin: true) }
  scope :all_except, ->(user) { where.not(id: user.id) }

  # Optimized visible_to scope
  scope :visible_to, ->(user) {
    if user&.admin?
      all
    elsif user
      blocked_ids = user.blocking_relationships.pluck(:blocked_id)
      blocked_by_ids = user.blocked_relationships.pluck(:blocker_id)
      excluded_ids = blocked_ids + blocked_by_ids

      # Regular users only see active users who haven't blocked them and they haven't blocked
      active.where.not(id: excluded_ids)
    else
      active # Non-logged in users see active users
    end
  }

  # ADMIN METHODS
  def admin?
    admin == true
  end

  def make_admin!
    update!(admin: true)
  end

  def remove_admin!
    update!(admin: false)
  end

  # ADMIN BAN METHODS (site-wide bans - prevent login)
  def banned?
    banned_at.present?
  end

  def ban!(banned_by_user, reason = nil)
    update!(
      banned_at: Time.current,
      banned_by: banned_by_user,
      ban_reason: reason
    )
  end

  def unban!
    update!(
      banned_at: nil,
      banned_by: nil,
      ban_reason: nil
    )
  end

  # Override Devise's active_for_authentication to check admin ban status
  def active_for_authentication?
    super && !banned?
  end

  # Custom message when account is banned by admin
  def inactive_message
    banned? ? :banned : super
  end

  # OPTIMIZED USER BLOCKING METHODS
  def block_user(user)
    return false if user == self
    return true if blocked?(user) # Already blocked

    begin
      blocked_users << user
      association(:blocked_users).reload if association(:blocked_users).loaded?
      true
    rescue => e
      Rails.logger.error "Error blocking user: #{e.message}"
      false
    end
  end

  def unblock_user(user)
    return false unless blocked?(user) # Not blocked

    begin
      blocked_users.delete(user)
      association(:blocked_users).reload if association(:blocked_users).loaded?
      true
    rescue => e
      Rails.logger.error "Error unblocking user: #{e.message}"
      false
    end
  end

  # Optimized blocked? method
  def blocked?(user)
    return false if user.nil?
    blocking_relationships.exists?(blocked_id: user.id)
  end

  # Optimized blocked_by? method
  def blocked_by?(user)
    return false if user.nil?
    blocked_relationships.exists?(blocker_id: user.id)
  end

  def mutually_blocked?(user)
    blocked?(user) || blocked_by?(user)
  end

  # Efficient method to get blocked user IDs
  def blocked_user_ids
    blocking_relationships.pluck(:blocked_id)
  end

  def blocked_by_user_ids
    blocked_relationships.pluck(:blocker_id)
  end

  # Check if this user's content should be visible to another user
  def content_visible_to?(viewer)
    return true if viewer&.admin? # Admins see everything
    return false if banned? # Admin-banned users' content is hidden
    return false if viewer && mutually_blocked?(viewer) # User-blocked users can't see each other
    true
  end

  # Optimized filter methods for relationships
  def visible_followers(current_user = nil)
    return followers.active if current_user&.admin?

    if current_user
      excluded_ids = current_user.blocked_user_ids + current_user.blocked_by_user_ids
      followers.active.where.not(id: excluded_ids)
    else
      followers.active
    end
  end

  def visible_following(current_user = nil)
    return following.active if current_user&.admin?

    if current_user
      excluded_ids = current_user.blocked_user_ids + current_user.blocked_by_user_ids
      following.active.where.not(id: excluded_ids)
    else
      following.active
    end
  end

  # to use email or username at login page
  def login
    @login || username || email
  end

  # to be able to login with username or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).find_by([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ])
  end

  def follow(other_user)
    return false if mutually_blocked?(other_user)
    return false if following?(other_user) # Prevent duplicates

    active_relationships.create(followed: other_user)
  end

  def unfollow(other_user)
    relationship = active_relationships.find_by(followed: other_user)
    relationship&.destroy
  end

  def following?(other_user)
    active_relationships.exists?(followed: other_user)
  end

  def posts_count
    if has_attribute?(:posts_count)
      read_attribute(:posts_count) || 0
    else
      posts.count
    end
  end

  def followers_count
    if has_attribute?(:followers_count)
      read_attribute(:followers_count) || 0
    else
      followers.count
    end
  end

  def following_count
    if has_attribute?(:following_count)
      read_attribute(:following_count) || 0
    else
      following.count
    end
  end

  def to_param
    username
  end

  # OPTIMIZED Message-related methods (respects both admin bans and user blocking)
  def conversations
    sent_to_ids = sent_messages.distinct.pluck(:receiver_id)
    received_from_ids = received_messages.distinct.pluck(:sender_id)
    user_ids = (sent_to_ids + received_from_ids).uniq

    # Filter out blocked users efficiently
    excluded_ids = blocked_user_ids + blocked_by_user_ids
    user_ids -= excluded_ids

    User.active.where(id: user_ids) # Only active (non-admin-banned) users
  end

  def conversation_with(other_user)
    return Message.none if mutually_blocked?(other_user) || other_user.banned?
    Message.between_users(self, other_user)
  end

  def unread_messages_count
    excluded_ids = blocked_user_ids + blocked_by_user_ids
    received_messages.joins(:sender).where(users: { banned_at: nil })
                    .where.not(sender_id: excluded_ids).unread.count
  end

  def unread_messages_from(other_user)
    return 0 if mutually_blocked?(other_user) || other_user.banned?
    received_messages.where(sender: other_user).unread.count
  end

  def last_message_with(other_user)
    conversation_with(other_user).last
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
