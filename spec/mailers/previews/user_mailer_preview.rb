class UserMailerPreview < ActionMailer::Preview
  def confirmation
    user = User.new(
      name: "John Doe",
      email: "john@example.com",
      confirmation_token: "abc123"
    )
    UserMailer.confirmation(user)
  end

  def welcome_email
    user = User.new(
      name: "Jane Smith",
      email: "jane@example.com"
    )
    UserMailer.welcome_email(user)
  end
end
