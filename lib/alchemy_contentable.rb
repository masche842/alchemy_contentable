module AlchemyContentable

  require 'alchemy_contentable/model_mixin'
  require 'alchemy_contentable/admin_controller_mixin'
  require 'alchemy_contentable/controller_mixin'  
  require 'alchemy_contentable/engine'
  require 'alchemy_contentable/migration_helper'

  require 'patches/resources_helper'
  require 'patches/resources_admin_controller_mixin'
  require 'patches/elements_controller_mixin'

  require 'alchemy_cms'


  class MonkeyPatching < Rails::Railtie
    # HAPPY MONKEYPATCHING!!
    config.after_initialize do
      require 'patches/element.rb'

      Alchemy::Admin::ElementsController.send(:include, AlchemyContentable::ElementsControllerMixin)
      Alchemy::Admin::ElementsController.send(:before_filter, :load_contentable_to_page, :only => [:index, :new, :create])

    end
  end


end
