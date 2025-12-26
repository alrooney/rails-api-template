class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(used: false).where("expires_at > ?", Time.current) }

  def self.generate_for(user)
    token = SecureRandom.urlsafe_base64(32)
    create!(
      user: user,
      token: token,
      expires_at: 1.hour.from_now
    )
  end

  def expired?
    expires_at < Time.current
  end

  def mark_as_used!
    update!(used: true)
  end

  def used?
    used
  end
end
