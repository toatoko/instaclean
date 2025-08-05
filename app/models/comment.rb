class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :content, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
  scope :limited_preview, ->(limit = 2) { recent.limit(limit) }

  has_many :reports, as: :reportable, dependent: :destroy
end
