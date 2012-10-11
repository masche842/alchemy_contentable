# This migration comes from alchemy_contentable (originally 20120222064040)
class AddContentableToAlchemyElements < ActiveRecord::Migration
  def change
    add_column :alchemy_elements, :contentable_id, :integer
    add_column :alchemy_elements, :contentable_type, :string
  end
end
