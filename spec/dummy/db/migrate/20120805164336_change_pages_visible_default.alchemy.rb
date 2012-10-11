# This migration comes from alchemy (originally 20110224105120)
class ChangePagesVisibleDefault < ActiveRecord::Migration

  def self.up
    change_column_default :pages, :visible, false
  end

  def self.down
    change_column_default :pages, :visible, true
  end

end