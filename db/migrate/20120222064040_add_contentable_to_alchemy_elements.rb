class AddContentableToAlchemyElements < ActiveRecord::Migration
  def change
    add_column :alchemy_elements, :contentable_id, :integer
    add_column :alchemy_elements, :contentable_type, :string
  end
end
