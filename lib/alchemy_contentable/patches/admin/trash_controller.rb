module AlchemyContentable
  module Patches
    module Admin
      module TrashController

        def self.included(c)
          c.send :include, AlchemyContentable::ContentableToPage
        end

        def index
          @elements = Alchemy::Element.trashed
          load_contentable_to_page
          #@page = Alchemy::Page.find_by_id(params[:page_id])
          @allowed_elements = Alchemy::Element.all_for_page(@page)
          @draggable_trash_items = {}
          @elements.each { |e| @draggable_trash_items["element_#{e.id}"] = e.belonging_cellnames(@page) }
          render :layout => false
        end

        def clear
          load_contentable_to_page
          @elements = Alchemy::Element.trashed
          @elements.map(&:destroy)
        end

      end
    end
  end
end

#require Alchemy::Engine.root.join('app', 'models', 'alchemy', 'element')
Alchemy::Admin::TrashController.send(:include, AlchemyContentable::Patches::Admin::TrashController)
