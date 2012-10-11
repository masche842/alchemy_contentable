# This migration comes from alchemy (originally 20100607162339)
class CreateElementsPages < ActiveRecord::Migration
  def self.up
    create_table :elements_pages, :id => false do |t|
      t.integer :element_id
      t.integer :page_id
    end
  end

  def self.down
    drop_table :elements_pages
  end
end
