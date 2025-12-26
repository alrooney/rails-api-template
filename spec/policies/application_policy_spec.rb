require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { double('User') }
  let(:record) { double('Record') }
  subject { described_class.new(user, record) }

  describe 'base methods' do
    it 'allows index? for authenticated users' do
      expect(subject.index?).to eq(true)
    end

    it 'denies index? for unauthenticated users' do
      policy = described_class.new(nil, record)
      expect(policy.index?).to eq(false)
    end

    it 'denies show?' do
      expect(subject.show?).to eq(false)
    end

    it 'denies create?' do
      expect(subject.create?).to eq(false)
    end

    it 'denies new? (delegates to create?)' do
      expect(subject.new?).to eq(false)
    end

    it 'denies update?' do
      expect(subject.update?).to eq(false)
    end

    it 'denies edit? (delegates to update?)' do
      expect(subject.edit?).to eq(false)
    end

    it 'denies destroy?' do
      expect(subject.destroy?).to eq(false)
    end
  end

  describe 'role-based helper methods' do
    let(:admin_user) { double('User') }
    let(:regular_user) { double('User') }

    it 'admin? returns true if user has admin role' do
      allow(admin_user).to receive(:has_role?).with(:admin).and_return(true)
      policy = described_class.new(admin_user, record)
      expect(policy.admin?).to eq(true)
    end

    it 'admin? returns false if user does not have admin role' do
      allow(regular_user).to receive(:has_role?).with(:admin).and_return(false)
      policy = described_class.new(regular_user, record)
      expect(policy.admin?).to eq(false)
    end

    it 'admin? returns false if user is nil' do
      policy = described_class.new(nil, record)
      expect(policy.admin?).to eq(false)
    end

    it 'admin? returns false and covers else branch when user has no admin role (real user)' do
      # Use a real user object to ensure the || false branch is executed
      real_user = create(:user)
      # Ensure user does not have admin role
      expect(real_user.has_role?(:admin)).to be false
      policy = described_class.new(real_user, record)
      expect(policy.admin?).to eq(false)
    end
  end

  describe 'Scope' do
    let(:scope) { double('Scope') }
    let(:user) { double('User') }

    it 'initializes with user and scope' do
      s = ApplicationPolicy::Scope.new(user, scope)
      expect(s.instance_variable_get(:@user)).to eq(user)
      expect(s.instance_variable_get(:@scope)).to eq(scope)
    end

    it 'raises NoMethodError for resolve by default' do
      s = ApplicationPolicy::Scope.new(user, scope)
      expect { s.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
    end

    describe 'admin? method' do
      it 'returns true if user has admin role' do
        admin_user = double('User')
        allow(admin_user).to receive(:has_role?).with(:admin).and_return(true)
        scope_instance = ApplicationPolicy::Scope.new(admin_user, scope)
        expect(scope_instance.send(:admin?)).to eq(true)
      end

      it 'returns false if user does not have admin role' do
        regular_user = double('User')
        allow(regular_user).to receive(:has_role?).with(:admin).and_return(false)
        scope_instance = ApplicationPolicy::Scope.new(regular_user, scope)
        expect(scope_instance.send(:admin?)).to eq(false)
      end

      it 'returns false if user is nil' do
        scope_instance = ApplicationPolicy::Scope.new(nil, scope)
        expect(scope_instance.send(:admin?)).to eq(false)
      end

      it 'returns false and covers else branch when user has no admin role (real user)' do
        # Use a real user object to ensure the || false branch is executed
        real_user = create(:user)
        # Ensure user does not have admin role
        expect(real_user.has_role?(:admin)).to be false
        scope_instance = ApplicationPolicy::Scope.new(real_user, scope)
        expect(scope_instance.send(:admin?)).to eq(false)
      end
    end
  end
end
