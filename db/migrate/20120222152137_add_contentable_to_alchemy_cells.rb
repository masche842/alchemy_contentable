# This migration comes from alchemy (originally 20120222152101)
class AddContentableToAlchemyCells < ActiveRecord::Migration
  def change
    add_column :alchemy_cells, :contentable_id, :integer

    add_column :alchemy_cells, :contentable_type, :string

  end
end
