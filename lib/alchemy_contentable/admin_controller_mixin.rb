# encoding: UTF-8
module AlchemyContentable
  module AdminControllerMixin

    def self.included(controller)
      controller.helper "alchemy/pages"
      controller.helper "alchemy/admin/pages"

      #controller.filter_access_to [:show, :unlock, :visit, :publish, :configure, :edit, :update, :destroy, :fold], :attribute_check => true
      #controller.filter_access_to [:index, :link, :layoutpages, :new, :switch_language, :create, :move, :flush], :attribute_check => false

      controller.cache_sweeper Alchemy::PagesSweeper, :only => [:publish], :if => proc { Alchemy::Config.get(:cache_pages) }
      controller.cache_sweeper Alchemy::ContentablesSweeper, :only => [:publish], :if => proc { Alchemy::Config.get(:cache_pages) }

    end


    def index
      if params[:query].blank?
        items = resource_handler.model
      else
        search_terms = ActiveRecord::Base.sanitize("%#{params[:query]}%")
        items = resource_handler.model.where(resource_handler.searchable_attributes.map { |attribute|
          "`#{resource_handler.model_name.pluralize}`.`#{attribute[:name]}` LIKE #{search_terms}"
        }.join(" OR "))
      end
      instance_variable_set("@#{resource_handler.resources_name}", items.page(params[:page] || 1).per(per_page_value_for_screen_size))
    end

    def show
      load_resource
      @page = resource_instance_variable
      @preview_mode = true
      # Setting the locale to pages language. so the page content has its correct translation
      ::I18n.locale = Alchemy::Language.get_default.code
      render :layout => layout_for_page
    end

    def new
      instance_variable_set("@#{resource_handler.model_name}", resource_handler.model.new)
      @page_layouts = Alchemy::PageLayout.get_layouts_for_select(session[:language_id], false)
      render :layout => false
    end

    # Edit the content of the page and all its elements and contents.
    def edit_content
      load_resource
      if resource_instance_variable.locked? && resource_instance_variable.locker && resource_instance_variable.locker.logged_in? && resource_instance_variable.locker != current_user
        flash[:notice] = t("This page is locked by %{name}", :name => (resource_instance_variable.locker.name rescue t('unknown')))
        redirect_to resources_path
      else
        resource_instance_variable.lock(current_user)
        @locked_contentables = resource_handler.model.all_locked_by(current_user)
      end
      @layoutpage = false
    end

    def update_content
      load_resource
      if resource_instance_variable.update_attributes(params[:page])
        @notice = t("Page saved", :name => resource_instance_variable.name)
        @while_page_edit = request.referer.include?('edit')
      else
        render_remote_errors(resource_instance_variable, "form#edit_page_#{resource_instance_variable.id} button.button")
      end
    end

    def link
      @url_prefix = ""
      if configuration(:show_real_root)
        @contentable_root = resource_handler.model.root
      else
        @contentable_root = resource_handler.model.language_root_for(session[:language_id])
      end
      @area_name = params[:area_name]
      @content_id = params[:content_id]
      @link_target_options = resource_handler.model.link_target_options
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

    # Leaves the page editing mode and unlocks the page for other users
    def unlock
      load_resource
      resource_instance_variable.unlock
      flash[:notice] = t("unlocked_page", :name => resource_instance_variable.name)
      @contentables_locked_by_user = resource_handler.model.all_locked_by(current_user)
      respond_to do |format|
        format.js
        format.html {
          redirect_to params[:redirect_to].blank? ? resource_url_scope.send("admin_#{resource_handler.resources_name}_path") : params[:redirect_to]
        }
      end
    end

    def visit
      load_resource
      resource_instance_variable.unlock
      redirect_to [resource_url_proxy, resource_instance_variable]
    end

    # Sets the page public and sweeps the page cache
    def publish
      load_resource
      resource_instance_variable.public = true
      resource_instance_variable.save
      flash[:notice] = t("page_published", :name => resource_instance_variable.name)
      redirect_back_or_to_default(resources_path)
    end

    def flush
      resource_handler.model.with_language(session[:language_id]).flushables.each do |page|
        expire_page(page)
      end
      respond_to do |format|
        format.js
      end
    end

    private

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

  end
end
