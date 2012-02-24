module AlchemyContentable
  module Admin
    class ContentableResourcesController < Alchemy::Admin::ResourcesController
      include AlchemyContentable::AdminControllerMixin
    end
  end
end
