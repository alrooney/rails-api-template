class CreateRoleAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :role_audits, id: :uuid do |t|
      t.references :user, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :role, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :resource_type
      t.uuid :resource_id
      t.string :action, null: false
      t.string :whodunnit
      t.timestamps
    end
  end
end
