# This migration comes from alchemy (originally 20110115123343)
class RemoveCssClassDefaultFromEssencePictures < ActiveRecord::Migration

  def self.up
    change_column_default :essence_pictures, :css_class, nil
  end

  def self.down
    change_column_default :essence_pictures, :css_class, "no_float"
  end

end