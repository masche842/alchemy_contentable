# This migration comes from alchemy (originally 20101216173323)
class AddDefaultToLanguages < ActiveRecord::Migration
  def self.up
    add_column :languages, :default, :boolean, :default => false
  end

  def self.down
    remove_column :languages, :default
  end
end
