class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name
      t.date :starts_at
      t.boolean :public
      t.boolean :locked
      t.integer :locked_by
      t.string :language_code
      t.integer :language_id
      t.string :page_layout

      t.timestamps
    end
  end
end
