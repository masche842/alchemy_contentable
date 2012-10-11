# This migration comes from alchemy (originally 20100607193653)
class CreateEssenceHtmls < ActiveRecord::Migration
  def self.up
    create_table :essence_htmls do |t|
      t.text :source
      t.userstamps
      t.timestamps
    end
  end

  def self.down
    drop_table :essence_htmls
  end
end
