# This migration comes from alchemy (originally 20120222161851)
class CreateAlchemySweepedContentables < ActiveRecord::Migration
  def change
    create_table :alchemy_sweeped_contentables do |t|
      t.string :contentable_type
      t.integer :contentable_id
      t.integer :element_id

      t.timestamps
    end
  end
end
