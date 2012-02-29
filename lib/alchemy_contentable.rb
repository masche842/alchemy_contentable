module AlchemyContentable

  require 'alchemy_contentable/engine'

  require 'alchemy_contentable/model_mixin'
  require 'alchemy_contentable/admin_controller_mixin'
  require 'alchemy_contentable/controller_mixin'
  require 'alchemy_contentable/migration_helper'

  #require 'patches/resources_helper'
  #require 'patches/resources_admin_controller'

  Engine.config.after_initialize do
    require 'patches/elements_controller'
    require 'patches/element.rb'
  end
end

class ActionController::Base
  include AlchemyContentable
end
