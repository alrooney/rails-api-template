class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked: false).where("expires_at > ?", Time.current) }

  def self.generate_for(user)
    token = SecureRandom.urlsafe_base64(32)
    create!(
      user: user,
      token: token,
      expires_at: 7.days.from_now
    )
  end

  def expired?
    expires_at < Time.current
  end

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked && !expired?
  end
end
