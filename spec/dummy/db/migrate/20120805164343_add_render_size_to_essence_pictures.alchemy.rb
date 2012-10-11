# This migration comes from alchemy (originally 20110707190728)
class AddRenderSizeToEssencePictures < ActiveRecord::Migration
  def self.up
    add_column :essence_pictures, :render_size, :string
  end

  def self.down
    remove_column :essence_pictures, :render_size
  end
end
