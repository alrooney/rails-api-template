class UserSerializer
  include JSONAPI::Serializer
  include AttachmentSerialization

  attributes :id, :name, :email, :phone, :email_confirmed, :phone_confirmed, :profile, :created_at, :updated_at, :roles

  attribute :roles do |user|
    user.roles.pluck(:name)
  end

  has_attachment :avatar
end
