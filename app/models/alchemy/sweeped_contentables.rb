class Alchemy::SweepedContentables < ActiveRecord::Base
  belongs_to :element, :class_name => 'Alchemy::Element'
  belongs_to :contentable, :polymorphic => true

end
