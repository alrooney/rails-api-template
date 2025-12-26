# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  permissions :index? do
    it "allows access to regular users" do
      expect(subject).to permit(regular_user, User)
    end
  end

  permissions :show? do
    it "allows users to see themselves" do
      expect(subject).to permit(regular_user, regular_user)
    end

    it "denies users from seeing others" do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it "allows admins to see any user" do
      expect(subject).to permit(admin_user, regular_user)
    end
  end

  permissions :create? do
    it "denies access to regular users" do
      expect(subject).not_to permit(regular_user, User)
    end

    it "allows access to admins" do
      expect(subject).to permit(admin_user, User)
    end
  end

  permissions :update? do
    it "allows users to update themselves" do
      expect(subject).to permit(regular_user, regular_user)
    end

    it "denies users from updating others" do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it "allows admins to update any user" do
      expect(subject).to permit(admin_user, other_user)
    end
  end

  permissions :destroy? do
    it "denies users from destroying themselves" do
      expect(subject).not_to permit(regular_user, regular_user)
    end

    it "denies users from destroying others" do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it "allows admins to destroy other users" do
      expect(subject).to permit(admin_user, regular_user)
    end

    it "denies admins from destroying themselves" do
      expect(subject).not_to permit(admin_user, admin_user)
    end
  end

  permissions :update_password? do
    it "allows users to update their own password" do
      expect(subject).to permit(regular_user, regular_user)
    end

    it "denies users from updating others' passwords" do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it "allows admins to update any user's password" do
      expect(subject).to permit(admin_user, other_user)
    end
  end

  describe "scope" do
    let!(:users) { [ admin_user, regular_user, other_user ] }

    it "shows all users to admins" do
      policy = described_class::Scope.new(admin_user, User)
      expect(policy.resolve.count).to eq(3)
    end

    it "shows only themselves to regular users" do
      policy = described_class::Scope.new(regular_user, User)
      expect(policy.resolve.count).to eq(1)
      expect(policy.resolve.first).to eq(regular_user)
    end
  end
end
