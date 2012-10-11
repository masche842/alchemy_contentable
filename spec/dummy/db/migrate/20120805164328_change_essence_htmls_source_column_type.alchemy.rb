# This migration comes from alchemy (originally 20100909140701)
class ChangeEssenceHtmlsSourceColumnType < ActiveRecord::Migration
  def self.up
    change_column :essence_htmls, :source, :text
  end

  def self.down
    change_column :essence_htmls, :source, :string
  end
end
