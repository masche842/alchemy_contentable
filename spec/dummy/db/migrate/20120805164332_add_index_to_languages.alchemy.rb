# This migration comes from alchemy (originally 20101216155216)
class AddIndexToLanguages < ActiveRecord::Migration
  def self.up
    add_index :languages, :code
  end

  def self.down
    remove_index :languages, :code
  end
end