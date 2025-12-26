require "rails_helper"
require "support/jwt_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  include JwtHelper
  let(:user) { create(:user) }
  let(:token) { generate_jwt_token(user) }

  it "successfully connects with valid JWT token" do
    connect "/cable?token=#{token}"
    expect(connection.current_user).to eq(user)
  end

  it "rejects connection with invalid token" do
    expect {
      connect "/cable?token=invalid"
    }.to have_rejected_connection
  end

  it "rejects connection with expired token" do
    expired_token = JWT.encode(
      { user_id: user.id, exp: 1.hour.ago.to_i },
      Rails.application.credentials.jwt_secret,
      "HS256"
    )
    expect {
      connect "/cable?token=#{expired_token}"
    }.to have_rejected_connection
  end

  it "rejects connection with no token" do
    expect {
      connect "/cable"
    }.to have_rejected_connection
  end
end
