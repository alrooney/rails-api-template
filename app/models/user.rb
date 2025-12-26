class User < ApplicationRecord
  rolify strict: true, after_add: :log_role_added, after_remove: :log_role_removed
  has_secure_password
  has_many :password_reset_tokens, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy
  has_paper_trail

  # Active Storage attachments
  has_one_attached :avatar

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :phone, with: ->(p) { format_phone_to_e164(p) }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, uniqueness: true, allow_blank: true, format: { with: /\A\+\d{10,15}\z/ }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :name, presence: true

  # Reset phone confirmation when phone number changes
  after_update_commit :handle_phone_change

  def phone_confirmed?
    phone_confirmed
  end

  def email_confirmed?
    email_confirmed
  end

  def generate_email_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
    self.confirmation_sent_at = Time.current
  end

  def generate_email_confirmation_token!
    generate_email_confirmation_token
    save!
  end

  def confirm_phone!
    update(
      phone_confirmed: true,
      phone_confirmation_sent_at: nil
    )
  end

  def confirm_email!
    update(
      email_confirmed: true,
      confirmation_token: nil,
      confirmation_sent_at: nil
    )
  end

  # Notification preferences and timezone helpers
  def notification_timezone
    profile.dig("preferences", "timezone") || "America/New_York"
  end

  def notifications_enabled?
    profile.dig("preferences", "notifications", "enabled") != false
  end

  def morning_notifications_enabled?
    notifications_enabled? && profile.dig("preferences", "notifications", "morning") != false
  end

  def midday_notifications_enabled?
    notifications_enabled? && profile.dig("preferences", "notifications", "midday") != false
  end

  def afternoon_notifications_enabled?
    notifications_enabled? && profile.dig("preferences", "notifications", "afternoon") != false
  end

  def evening_notifications_enabled?
    notifications_enabled? && profile.dig("preferences", "notifications", "evening") != false
  end

  def wind_down_notifications_enabled?
    notifications_enabled? && profile.dig("preferences", "notifications", "wind_down") != false
  end

  private

  def self.format_phone_to_e164(phone)
    return nil if phone.blank?
    # Remove all non-digit characters
    digits_only = phone.gsub(/\D/, "")
    # If the phone contains letters or is too long, return as is
    return phone if phone.match?(/[^\d\s\-\(\)\+\.]/) || digits_only.length > 15
    # Handle US/Canada numbers (assuming +1 country code)
    if digits_only.length == 10
      "+1#{digits_only}"
    elsif digits_only.length == 11 && digits_only.start_with?("1")
      "+#{digits_only}"
    elsif digits_only.length >= 10 && digits_only.length <= 15
      # For international numbers, assume they already have country code
      "+#{digits_only}"
    else
      # If it doesn't match expected patterns, return as is
      phone
    end
  end

  def log_role_added(role)
    Rails.logger.info "Role '#{role.name}' added to User #{id} on #{role.resource_type}##{role.resource_id} by #{PaperTrail.request.whodunnit}"
    RoleAudit.create!(user: self, role: role, resource: role.resource, action: "added", whodunnit: PaperTrail.request.whodunnit)
  end

  def log_role_removed(role)
    Rails.logger.info "Role '#{role.name}' removed from User #{id} on #{role.resource_type}##{role.resource_id} by #{PaperTrail.request.whodunnit}"
    RoleAudit.create!(user: self, role: role, resource: role.resource, action: "removed", whodunnit: PaperTrail.request.whodunnit)
  end

  def handle_phone_change
    if saved_change_to_phone? && phone.present?
      # Reset confirmation status for the new phone number
      update_columns(
        phone_confirmed: false,
        phone_confirmation_sent_at: nil
      )
      # Send verification code for the new phone number
      SendPhoneConfirmationJob.perform_later(email)
    end
  end
end
