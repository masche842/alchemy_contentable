# encoding: UTF-8
module AlchemyContentable
  module AdminControllerMixin

    def self.included(controller)
      controller.helper "alchemy/pages"
      controller.helper "alchemy/admin/pages"
      controller.helper ResourcesHelper

      controller.before_filter :set_translation, :except => [:show]

  #TODO    mod.filter_access_to [:show, :unlock, :visit, :publish, :configure, :edit, :update, :destroy, :fold], :attribute_check => true, :load_method => :get_contentable_from_id, :model => Alchemy::Page
      controller.filter_access_to [:index, :link, :layoutpages, :new, :switch_language, :create, :move, :flush], :attribute_check => false

      controller.cache_sweeper Alchemy::PagesSweeper, :only => [:publish], :if => proc { Alchemy::Config.get(:cache_pages) }

    end


    def index
      if !params[:query].blank?
        search_terms = ActiveRecord::Base.sanitize("%#{params[:query]}%")
        items = resource_model.where(searchable_resource_attributes.map { |attribute|
          "`#{namespaced_resources_name}`.`#{attribute[:name]}` LIKE #{search_terms}"
        }.join(" OR "))
      else
        items = resource_model
      end
      instance_variable_set("@#{resources_name}", items.paginate(:page => params[:page] || 1, :per_page => per_page_value_for_screen_size))
    end

    def show
      load_resource
      @page = resource_instance_variable
      @preview_mode = true
      #@contentable = resource_model.language_root_for(session[:language_id])
      # Setting the locale to pages language. so the page content has its correct translation
      ::I18n.locale = resource_instance_variable.language_code
      render :layout => layout_for_page
    end

    def new
      instance_variable_set("@#{resource_model_name}", resource_model.new)
      @page_layouts = Alchemy::PageLayout.get_layouts_for_select(session[:language_id], false)
      render :layout => false
    end

    def create
      language = Alchemy::Language.get_default
      params[resource_model_name.to_sym][:language_id] = language.id
      params[resource_model_name.to_sym][:language_code] = language.code

      instance_variable_set("@#{resource_model_name}", resource_model.new(params[resource_model_name.to_sym]))
      resource_instance_variable.save
      render_errors_or_redirect(
        resource_instance_variable,
        resource_url_scope.url_for({:action => :index}),
        flash_notice_for_resource_action
      )
    end

    # Edit the content of the page and all its elements and contents.
    def edit
      load_resource
      if resource_instance_variable.locked? && resource_instance_variable.locker && resource_instance_variable.locker.logged_in? && resource_instance_variable.locker != current_user
        flash[:notice] = t("This page is locked by %{name}", :name => (resource_instance_variable.locker.name rescue t('unknown')))
        redirect_to resource_url_scope.send("admin_#{resources_name}_path")
      else
        resource_instance_variable.lock(current_user)
        @locked_contentables = resource_model.all_locked_by(current_user)
      end
      @layoutpage = false
    end

    # Set page configuration like page names, meta tags and states.
    def configure
      # fetching page via before filter
      if @contentable.redirects_to_external?
        render :action => 'configure_external', :layout => false
      else
        render :layout => false
      end
    end

    def update
      # fetching page via before filter
      if @contentable.update_attributes(params[:page])
        @notice = t("Page saved", :name => @contentable.name)
        @while_page_edit = request.referer.include?('edit')
      else
        render_remote_errors(@contentable, "form#edit_page_#{@contentable.id} button.button")
      end
    end

    def destroy
      # fetching page via before filter
      name = @contentable.name
      @contentable_id = @contentable.id
      @layoutpage = @contentable.layoutpage?
      session[:language_id] = @contentable.language_id
      if @contentable.destroy
        @contentable_root = resource_model.language_root_for(session[:language_id])
        get_clipboard('pages').delete(@contentable.id)
        @message = t("Page deleted", :name => name)
        flash[:notice] = @message
        respond_to do |format|
          format.js
        end
      end
    end

    def link
      @url_prefix = ""
      if configuration(:show_real_root)
        @contentable_root = resource_model.root
      else
        @contentable_root = resource_model.language_root_for(session[:language_id])
      end
      @area_name = params[:area_name]
      @content_id = params[:content_id]
      @link_target_options = resource_model.link_target_options
      @attachments = Attachment.all.collect { |f| [f.name, download_attachment_path(:id => f.id, :name => f.name)] }
      if params[:link_urls_for] == "newsletter"
        # TODO: links in newsletters has to go through statistic controller. therfore we have to put a string inside the content_rtfs and replace this string with recipient.id before sending the newsletter.
        #@url_prefix = "#{current_server}/recipients/reacts"
        @url_prefix = current_server
      end
      if multi_language?
        @url_prefix = "#{session[:language_code]}/"
      end
      render :layout => false
    end

    def fold
      # @contentable is fetched via before filter
      @contentable.fold(current_user.id, !@contentable.folded?(current_user.id))
      @contentable.save
      respond_to do |format|
        format.js
      end
    end

    # Leaves the page editing mode and unlocks the page for other users
    def unlock
      # fetching page via before filter
      @contentable.unlock
      flash[:notice] = t("unlocked_page", :name => @contentable.name)
      @contentables_locked_by_user = resource_model.all_locked_by(current_user)
      respond_to do |format|
        format.js
        format.html {
          redirect_to params[:redirect_to].blank? ? admin_pages_path : params[:redirect_to]
        }
      end
    end

    def visit
      @contentable.unlock
      redirect_to show_page_path(:urlname => @contentable.urlname, :lang => multi_language? ? @contentable.language_code : nil)
    end

    # Sets the page public and sweeps the page cache
    def publish
      # fetching page via before filter
      @contentable.public = true
      @contentable.save
      flash[:notice] = t("page_published", :name => @contentable.name)
      redirect_back_or_to_default(admin_pages_path)
    end

    def copy_language_tree
      # copy language root from old to new language
      if params[:layoutpage]
        original_language_root = resource_model.layout_root_for(params[:languages][:old_lang_id])
      else
        original_language_root = resource_model.language_root_for(params[:languages][:old_lang_id])
      end
      new_language_root = resource_model.copy(
        original_language_root,
        :language_id => params[:languages][:new_lang_id],
        :language_code => session[:language_code],
        :layoutpage => params[:layoutpage]
      )
      new_language_root.move_to_child_of resource_model.root
      original_language_root.copy_children_to(new_language_root)
      flash[:notice] = t('language_pages_copied')
      redirect_to params[:layoutpage] == "true" ? admin_layoutpages_path : :action => :index
    end

    def sort
      @contentable_root = resource_model.language_root_for(session[:language_id])
      @sorting = true
    end

    def order
      @contentable_root = resource_model.language_root_for(session[:language_id])

      # Taken from https://github.com/matenia/jQuery-Awesome-Nested-Set-Drag-and-Drop
      neworder = JSON.parse(params[:set])
      prev_item = nil
      neworder.each do |item|
        dbitem = resource_model.find(item['id'])
        prev_item.nil? ? dbitem.move_to_child_of(@contentable_root) : dbitem.move_to_right_of(prev_item)
        sort_children(item, dbitem) unless item['children'].nil?
        prev_item = dbitem.reload
      end

      flash[:notice] = t("Pages order saved")
      @redirect_url = admin_pages_path
      render :action => :redirect
    end

    def switch_language
      set_language_from(params[:language_id])
      redirect_path = request.referer.include?('admin/layoutpages') ? admin_layoutpages_path : admin_pages_path
      if request.xhr?
        @redirect_url = redirect_path
        render :action => :redirect
      else
        redirect_to redirect_path
      end
    end

    def flush
      resource_model.with_language(session[:language_id]).flushables.each do |page|
        expire_page(page)
      end
      respond_to do |format|
        format.js
      end
    end

    private

    def get_contentable_from_id
      @contentable ||= resource_model.find(params[:id])
    end

    def pages_from_raw_request
      request.raw_post.split('&').map { |i| i = {i.split('=')[0].gsub(/[^0-9]/, '') => i.split('=')[1]} }
    end

    def expire_page(page)
      return if page.do_not_sweep
      # TODO: We should change this back to expire_action after Rails 3.2 was released.
      # expire_action(
      # 	alchemy.show_page_url(
      # 		:urlname => page.urlname_was,
      # 		:lang => multi_language? ? page.language_code : nil
      # 	)
      # )
      # Temporarily fix for Rails 3 bug
      expire_fragment(ActionController::Caching::Actions::ActionCachePath.new(
                        self,
                        alchemy.show_page_url(
                          :urlname => page.urlname_was,
                          :lang => multi_language? ? page.language_code : nil
                        ),
                        false
                      ).path)
    end

    # Taken from https://github.com/matenia/jQuery-Awesome-Nested-Set-Drag-and-Drop
    def sort_children(element, dbitem)
      prevchild = nil
      element['children'].each do |child|
        childitem = resource_model.find(child['id'])
        prevchild.nil? ? childitem.move_to_child_of(dbitem) : childitem.move_to_right_of(prevchild)
        sort_children(child, childitem) unless child['children'].nil?
        prevchild = childitem
      end
    end

  end 
end
