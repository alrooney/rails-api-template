# Preview all emails at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwords_mailer/reset
  def reset
    user = User.first || User.create!(email: "preview@example.com", password: "password123", name: "Preview User", email_confirmed: true)
    token = "sample-reset-token-123"
    PasswordsMailer.reset(user, token)
  end
end
