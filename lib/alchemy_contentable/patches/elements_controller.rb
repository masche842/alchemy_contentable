module AlchemyContentable
  module ElementsControllerMixin

    def index
      @cells = @page.cells
      if @cells.blank?
        @elements = @page.elements.not_trashed
      else
        @elements = @page.elements_grouped_by_cells
      end
      render :layout => false
    end

    def list
      @page_id = @page.id
      if @page_id.blank? and not params[:page_urlname].blank?
        @page_id = Page.find_by_urlname_and_language_id(params[:page_urlname], session[:language_id]).id
      end
      @elements = Alchemy::Element.find_all_by_page_id_and_public(@page_id, true)
    end

    def new
      @element = @page.elements.build
      @elements = Alchemy::Element.all_for_page(@page)
      clipboard_elements = get_clipboard('elements')
      unless clipboard_elements.blank?
        @clipboard_items = Alchemy::Element.all_from_clipboard_for_page(clipboard_elements, @page)
      end
      render :layout => false
    end

    # Creates a element as discribed in config/alchemy/elements.yml on page via AJAX.
    def create
      @paste_from_clipboard = !params[:paste_from_clipboard].blank?
      @element = Alchemy::Element.new_from_scratch(params[:element])
      put_element_in_cell if @page.can_have_cells?
      @element.contentable = @page
      if @element.save
        render :action => :create
      else
        render_remote_errors(@element, 'form#new_element button.button')
      end
    end

    # Saves all contents in the elements by calling save_content on each content
    # And then updates the element itself.
    # If a Ferret::FileNotFoundError raises we gonna catch it and rebuilding the index.
    def update
      @element = Alchemy::Element.find_by_id(params[:id])
      if @element.save_contents(params)
        @page = @element.page
        @element.public = !params[:public].nil?
        @element_validated = @element.save!
      else
        @element_validated = false
        @notice = t('Validation failed')
        @error_message = "<h2>#{@notice}</h2><p>#{t('Please check contents below.')}</p>".html_safe
      end
    end

    # Trashes the Element instead of deleting it.
    def trash
      @element = Alchemy::Element.find(params[:id])
      @page_id = @element.page_id
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
      @page = @element.page
      @element.folded = !@element.folded
      @element.save
    end


    protected

    def load_contentable_to_page
      if params[:contentable_type].present? and params[:contentable_id].present?
        contentable_type = params[:contentable_type]
        contentable_id =params[:contentable_id]
      elsif params[:element].present? and params[:element][:contentable_type].present? and params[:element][:contentable_id].present?
        contentable_type = params[:element][:contentable_type]
        contentable_id =params[:element][:contentable_id]
      else
        contentable_type = 'Alchemy::Page'
        contentable_id = (params[:page_id].presence or params[:element][:page_id])
        @page = Alchemy::Page.find(contentable_id)
      end
      contentable_model = contentable_type.classify.constantize
      @page ||= contentable_model.includes(:elements => :contents).find(contentable_id)
    end


  end
end

require Alchemy::Engine.root.join('app', 'models', 'alchemy', 'element')
Alchemy::ElementsController.send(:include, AlchemyContentable::ElementsControllerMixin)
Alchemy::ElementsController.send(:before_filter, :load_contentable_to_page, :only => [:index, :list, :new, :create])



