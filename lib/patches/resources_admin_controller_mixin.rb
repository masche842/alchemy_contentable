module AlchemyContentable
  module ResourcesAdminControllerMixin

    include ResourcesHelper

    def self.included(c)
      c.helper ResourcesHelper
    end

    protected

    # Returns a translated +flash[:notice]+.
    # The key should look like "Modelname successfully created|updated|destroyed."
    def flash_notice_for_resource_action(action = params[:action])
      case action.to_sym
        when :create
          verb = "created"
        when :update
          verb = "updated"
        when :destroy
          verb = "removed"
      end
      flash[:notice] = t("#{resource_model_name.classify} successfully #{verb}", :default => t("Succesfully #{verb}"))
    end

    def load_resource
      instance_variable_set("@#{resource_model_name}", resource_model.find(params[:id]))
    end

  end
end