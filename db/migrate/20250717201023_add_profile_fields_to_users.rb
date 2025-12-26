class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_profile_complete, :boolean, default: false, null: false
    add_column :users, :require_password_change, :boolean, default: false, null: false
    add_column :users, :profile, :jsonb, default: {}, null: false

    add_index :users, :profile, using: :gin
  end
end
