module AlchemyContentable
  module Patches
    module Admin
      module ElementsController

        def self.included(c)
          c.send :include, AlchemyContentable::ContentableToPage
        end

        def index
          #@page = Page.find(params[:page_id], :include => {:elements => :contents})
          @cells = @page.cells
          if @cells.blank?
            @elements = @page.elements.not_trashed
          else
            @elements = @page.elements_grouped_by_cells
          end
          render :layout => false
        end

        def list
          @page_id = params[:page_id]
          if @page_id.blank? && !params[:page_urlname].blank?
            @page_id = Page.find_by_urlname_and_language_id(params[:page_urlname], session[:language_id]).id
          end
          @elements = Alchemy::Element.find_all_by_page_id_and_public(@page_id, true)
        end

        def new
          #@page = Page.find_by_id(params[:page_id])
          @element = @page.elements.build
          @elements = Alchemy::Element.all_for_page(@page)
          clipboard_elements = get_clipboard[:elements]
          unless clipboard_elements.blank?
            @clipboard_items = Alchemy::Element.all_from_clipboard_for_page(clipboard_elements, @page)
          end
          render :layout => false
        end

        # Creates a element as described in config/alchemy/elements.yml on page via AJAX.
        def create
          @paste_from_clipboard = !params[:paste_from_clipboard].blank?
          if @paste_from_clipboard
            source_element = Alchemy::Element.find(element_from_clipboard[:id])
            @element = Alchemy::Element.copy(source_element, {:page_id => @page.id})
            if element_from_clipboard[:action] == 'cut'
              @cutted_element_id = source_element.id
              @clipboard.remove :elements, source_element.id
              source_element.destroy
            end
          else
            @element = Alchemy::Element.new_from_scratch(params[:element])
          end
          put_element_in_cell if @page.can_have_cells?
          @element.page_or_contentable = @page
          if @element.save
            render :action => :create
          else
            render_remote_errors(@element, 'form#new_alchemy_element button.button')
          end
        end

        # Saves all contents in the elements by calling save_content on each content
        # And then updates the element itself.
        # If a Ferret::FileNotFoundError raises we gonna catch it and rebuilding the index.
        def update
          @element = Alchemy::Element.find_by_id(params[:id])
          if @element.save_contents(params)
            @page = @element.page_or_contentable
            @element.public = !params[:public].nil?
            @element_validated = @element.save!
          else
            @element_validated = false
            @notice = t('Validation failed')
            @error_message = "<h2>#{@notice}</h2><p>#{t(:content_validations_headline)}</p>".html_safe
          end
        end

        # Trashes the Element instead of deleting it.
        def trash
          @element = Alchemy::Element.find(params[:id])
          @page = @element.page_or_contentable
          @element.trash
        end

        def order
          params[:element_ids].each do |element_id|
            element = Alchemy::Element.find(element_id)
            if element.trashed?
              element.page_id = params[:page_id]
              element.cell_id = params[:cell_id]
              element.insert_at
            end
            element.move_to_bottom
          end
        end

        def fold
          @element = Alchemy::Element.find(params[:id])
          @page = @element.page_or_contentable
          @element.folded = !@element.folded
          @element.save
        end


        protected

        def put_element_in_cell
          element_with_cell_name = @paste_from_clipboard ? params[:paste_from_clipboard] : params[:element][:name]
          cell_definition = Cell.definition_for(element_with_cell_name.split('#').last) if !element_with_cell_name.blank?
          if cell_definition
            @cell = @page.cells.find_or_create_by_name(cell_definition['name'])
            @element.cell = @cell
            return true
          else
            return false
          end
        end

        def element_from_clipboard
          @clipboard = get_clipboard
          @clipboard.get(:elements, params[:paste_from_clipboard])
        end

      end
    end
  end
end

require Alchemy::Engine.root.join('app', 'models', 'alchemy', 'element')
Alchemy::ElementsController.send(:include, AlchemyContentable::Patches::Admin::ElementsController)
Alchemy::ElementsController.send(:before_filter, :load_contentable_to_page, :only => [:index, :list, :new, :create])
