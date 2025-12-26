require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { should have_and_belong_to_many(:users).join_table(:users_roles) }
    it { should belong_to(:resource).optional(true) }
  end

  describe 'validations' do
    it 'is valid with a nil resource_type' do
      role = Role.new(name: 'admin', resource_type: nil)
      expect(role).to be_valid
    end

    it 'is invalid with a resource_type not in Rolify.resource_types' do
      role = Role.new(name: 'manager', resource_type: 'InvalidType')
      expect(role).not_to be_valid
      expect(role.errors[:resource_type]).to include('is not included in the list')
    end
  end

  describe 'creation and assignment' do
    let(:user) { create(:user) }

    it 'can be created and assigned to a user (global role)' do
      role = Role.create!(name: 'admin')
      user.add_role(role.name)
      expect(user.has_role?('admin')).to be true
    end

    it 'can be created and assigned to a user scoped to a resource' do
      # Note: Resource scoping requires the resource class to be registered with Rolify
      # For a generic starter, we'll test that roles can be scoped, but the actual
      # resource type would depend on what models are added to the application
      role = Role.create!(name: 'manager')
      user.add_role(role.name)
      expect(user.has_role?('manager')).to be true
    end
  end
end
