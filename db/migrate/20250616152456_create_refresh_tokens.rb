class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.boolean :revoked, default: false, null: false

      t.timestamps
    end

    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :expires_at
  end
end
