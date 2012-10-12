module AlchemyContentable

  require 'alchemy_contentable/engine'

  require 'alchemy_contentable/contentable_to_page'
  require 'alchemy_contentable/migration_helper'

  require 'alchemy_contentable/model_mixin'
  require 'alchemy_contentable/admin_controller_mixin'
  require 'alchemy_contentable/controller_mixin'

  Engine.config.after_initialize do
    require 'alchemy_contentable/patches/admin/trash_controller'
    require 'alchemy_contentable/patches/admin/elements_controller'
    require 'alchemy_contentable/patches/element.rb'
    require 'alchemy_contentable/patches/content.rb'
  end
end

class ActionController::Base
  include AlchemyContentable
end
