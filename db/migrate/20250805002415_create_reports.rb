class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.text :reason
      t.string :status, default: "pending"
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
