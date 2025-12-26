class RemovePhoneConfirmationTokenFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :phone_confirmation_token, if_exists: true
    remove_column :users, :phone_confirmation_token, if_exists: true
  end
end
