module AlchemyContentable

  require 'alchemy_contentable/engine'

  require 'alchemy_contentable/model_mixin'
  require 'alchemy_contentable/admin_controller_mixin'
  require 'alchemy_contentable/controller_mixin'
  require 'alchemy_contentable/migration_helper'

  Engine.config.after_initialize do
    require 'alchemy_contentable/patches/elements_controller'
    require 'alchemy_contentable/patches/element.rb'
  end
end

class ActionController::Base
  include AlchemyContentable
end
