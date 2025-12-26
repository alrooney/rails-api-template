class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # this allows us to do first and last on models that use uuids
  self.implicit_order_column = :created_at
end
