class AddPhoneConfirmationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :phone_confirmed, :boolean, default: false, null: false
    add_column :users, :phone_confirmation_token, :string
    add_column :users, :phone_confirmation_sent_at, :datetime

    add_index :users, :phone, unique: true
    add_index :users, :phone_confirmation_token, unique: true
  end
end
