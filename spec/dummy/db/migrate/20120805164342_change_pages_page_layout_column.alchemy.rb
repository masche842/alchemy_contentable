# This migration comes from alchemy (originally 20110530102804)
class ChangePagesPageLayoutColumn < ActiveRecord::Migration

  def self.up
    change_column :pages, :page_layout, :string, :null => true
  end

  def self.down
    change_column :pages, :page_layout, :string, :null => false
  end

end
