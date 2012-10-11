# This migration comes from alchemy (originally 20101109150312)
class AlterPagesVisibleColumnDefault < ActiveRecord::Migration
  def self.up
    change_column_default :pages, :visible, true
  end

  def self.down
    change_column_default :pages, :visible, false
  end
end
