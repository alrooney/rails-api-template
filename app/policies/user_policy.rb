# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  def me?
    # Any authenticated user can access their own information
    user.present?
  end

  def show?
    return true if admin?
    return true if record == user
    false
  end

  def create?
    admin?
  end

  def update?
    return true if admin?
    return true if record == user
    false
  end

  def destroy?
    return false if record == user
    return true if admin?
    false
  end

  def update_password?
    update?
  end

  private

  def admin?
    user.has_role?(:admin)
  end
end
