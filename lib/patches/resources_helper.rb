module AlchemyContentable
  module ResourcesHelper

    def resources_name
      @resources_name ||= params[:controller].split('/').last
    end

    def namespaced_resources_name
      if resource_namespaced?
        @namespaced_resources_name ||= "#{resource_namespace}_#{resources_name}".underscore
      else
        @namespaced_resources_name ||= resources_name
      end
    end

    def resource_model_name
      @resource_model_name ||= resources_name.singularize
    end

    def resource_model
      @resource_model ||= (resource_namespace == "Admin" ? resource_model_name : "#{resource_namespace}/#{resource_model_name}").classify.constantize
    end

    def resource_attributes
      @resource_attributes ||= resource_model.columns.collect do |col|
        unless ["id", "updated_at", "created_at", "creator_id", "updater_id"].include?(col.name)
          {:name => col.name, :type => col.type}
        end
      end.compact
    end

    def searchable_resource_attributes
      resource_attributes.select { |a| a[:type] == :string }
    end

    def resource_window_size
      @resource_window_size ||= "400x#{100 + resource_attributes.length * 35}"
    end

    def resource_instance_variable
      instance_variable_get("@#{resource_model_name}")
    end

    def resources_instance_variable
      instance_variable_get("@#{resources_name}")
    end

    def resource_namespaced?
      parts = controller_path.split('/')
      parts.length > 1 && parts.first != 'admin'
    end

    def resource_namespace
      @resource_namespace ||= self.class.to_s.split("::").first if resource_namespaced?
    end

    def resource_url_scope
      if is_alchemy_module?
        eval(alchemy_module['engine_name'])
      else
        main_app
      end
    end

    def is_alchemy_module?
      !alchemy_module.nil? && !alchemy_module['engine_name'].blank?
    end

    def alchemy_module
      @alchemy_module ||= module_definition_for(:controller => params[:controller], :action => 'index')
    end

    def resources_permission
      (resource_namespaced? ? "#{resource_namespace.underscore}_admin_#{resources_name}" : "admin_#{resources_name}").to_sym
    end
  end
end