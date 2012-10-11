# This migration comes from alchemy (originally 20110414163140)
class RemoveDisplayNameFromElements < ActiveRecord::Migration

  def self.up
    remove_column :elements, :display_name
  end

  def self.down
    add_column :elements, :display_name, :string
  end

end
