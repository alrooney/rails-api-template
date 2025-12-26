require 'rails_helper'

RSpec.describe RoleAudit, type: :model do
  let(:user) { create(:user) }
  let(:role) { Role.create!(name: 'admin') }

  it 'is valid with valid attributes' do
    audit = described_class.new(user: user, role: role, action: 'added', whodunnit: 'admin@example.com')
    expect(audit).to be_valid
  end

  it 'requires an action' do
    audit = described_class.new(user: user, role: role, whodunnit: 'admin@example.com')
    expect(audit).not_to be_valid
    expect(audit.errors[:action]).to be_present
  end

  it 'belongs to user and role' do
    audit = described_class.create!(user: user, role: role, action: 'added', whodunnit: 'admin@example.com')
    expect(audit.user).to eq(user)
    expect(audit.role).to eq(role)
  end

  it 'can have an optional resource (polymorphic)' do
    resource_user = create(:user)
    audit = described_class.create!(user: user, role: role, resource: resource_user, action: 'added', whodunnit: 'admin@example.com')
    expect(audit.resource).to eq(resource_user)
    expect(audit.resource_type).to eq('User')
    expect(audit.resource_id).to eq(resource_user.id)
  end

  it 'can be created via user role assignment' do
    PaperTrail.request.whodunnit = 'auditor@example.com'
    expect {
      user.add_role(:admin)
    }.to change { RoleAudit.where(user: user, action: 'added').count }.by(1)
    audit = RoleAudit.where(user: user, action: 'added').order(:created_at).last
    expect(audit.user).to eq(user)
    expect(audit.role.name).to eq('admin')
    expect(audit.action).to eq('added')
    expect(audit.whodunnit).to eq('auditor@example.com')
  end

  it 'can be created via user role removal' do
    user.add_role(:admin)
    PaperTrail.request.whodunnit = 'auditor@example.com'
    expect {
      user.remove_role(:admin)
    }.to change { RoleAudit.where(user: user, action: 'removed').count }.by(1)
    audit = RoleAudit.where(user: user, action: 'removed').order(:created_at).last
    expect(audit.user).to eq(user)
    expect(audit.action).to eq('removed')
    expect(audit.whodunnit).to eq('auditor@example.com')
  end
end
