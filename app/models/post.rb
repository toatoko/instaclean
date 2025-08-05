class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  before_create :set_active

  has_one_attached :image

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  has_many :reports, as: :reportable, dependent: :destroy

  validates :image, presence: true
  validates :user, presence: true
  scope :active, -> { where active: true }

  def set_active
    self.active = true
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  def likes_count
    # Use counter cache if available, otherwise fall back to count
    if has_attribute?(:likes_count)
      read_attribute(:likes_count) || 0
    else
      likes.count
    end
  end

  def preview_comments(limit = 2)
    comments.includes(:user).recent.limit(limit)
  end
  def comments_count
    # Use counter cache if available, otherwise fall back to count
    if has_attribute?(:comments_count)
      read_attribute(:comments_count) || 0
    else
      comments.count
    end
  end
end
