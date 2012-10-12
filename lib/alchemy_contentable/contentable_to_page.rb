module AlchemyContentable
  module ContentableToPage
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