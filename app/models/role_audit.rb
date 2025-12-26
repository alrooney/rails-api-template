class RoleAudit < ApplicationRecord
  belongs_to :user
  belongs_to :role, optional: true
  belongs_to :resource, polymorphic: true, optional: true
  validates :action, presence: true
end
