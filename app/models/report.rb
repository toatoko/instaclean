# app/models/report.rb
class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :reason, presence: true
  validates :reporter, presence: true

  # Scopes for status
  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where(status: "resolved") }
  scope :dismissed, -> { where(status: "dismissed") }

  # Add helper methods for status checks
  def pending?
    status == "pending"
  end

  def resolved?
    status == "resolved"
  end

  def dismissed?
    status == "dismissed"
  end
end
