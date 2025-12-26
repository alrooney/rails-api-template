require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user) { create(:user) }
  let(:serialized) { described_class.new(user).serializable_hash[:data][:attributes] }

  it 'includes expected attributes' do
    expect(serialized).to include(
      :id, :name, :email, :phone, :email_confirmed,
      :phone_confirmed, :profile, :created_at, :updated_at, :roles, :avatar_url, :avatar_info
    )
  end

  context 'when no avatar is attached' do
    it 'returns nil for avatar_url' do
      expect(serialized[:avatar_url]).to be_nil
    end

    it 'returns nil for avatar_info' do
      expect(serialized[:avatar_info]).to be_nil
    end
  end

  context 'when an avatar is attached' do
    before do
      user.avatar.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
        filename: 'avatar.jpg',
        content_type: 'image/jpeg'
      )
    end

    it 'returns an avatar_url' do
      avatar_url = described_class.new(user).serializable_hash[:data][:attributes][:avatar_url]
      expect(avatar_url).to be_present
      expect(avatar_url).to include('rails/active_storage/blobs')
    end

    it 'returns avatar_info with correct details' do
      avatar_info = described_class.new(user).serializable_hash[:data][:attributes][:avatar_info]
      expect(avatar_info).to be_present
      expect(avatar_info[:filename]).to eq('avatar.jpg')
      expect(avatar_info[:content_type]).to eq('image/jpeg')
      expect(avatar_info[:byte_size]).to be > 0
      expect(avatar_info[:checksum]).to be_present
    end
  end
end
