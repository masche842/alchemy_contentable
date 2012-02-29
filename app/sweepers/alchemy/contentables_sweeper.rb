module Alchemy
	class ContentablesSweeper < ActionController::Caching::Sweeper

		def after_update(contentable)
			unless contentable.layoutpage?
				expire_contentable(contentable)
				check_multipage_elements(contentable)
			end
		end

		def after_destroy(contentable)
			unless contentable.layoutpage?
				expire_contentable(contentable)
				check_multipage_elements(contentable)
			end
		end

	private

		def check_multipage_elements(contentable)
			contentable.elements.each do |element|
        to_sweep_contentables = element.send("to_sweep_#{contentable.class.name.underscore.split('/').last.pluralize}")
				# are their pages beneath mine?
				unless to_sweep_contentables.detect{ |d| d != contentable }.nil?
					# yepp! there are more pages than mine
					contentables = to_sweep_contentables.find_all_by_public_and_locked(true, false)
					unless contentables.blank?
						# expire current page, even if it's locked
						contentables.push(contentable).each do |contentable|
							expire_contentable(contentable)
						end
					end
				end
			end
		end

		def expire_contentable(contentable)
			return if contentable.do_not_sweep
			# TODO: We should change this back to expire_action after Rails 3.2 was released.
			# expire_action(
			# 	alchemy.show_page_url(
			# 		:urlname => page.urlname_was,
			# 		:lang => multi_language? ? page.language_code : nil
			# 	)
			# )
			# Temporarily fix for Rails 3 bug
      return if alchemy.nil?
			expire_fragment(ActionController::Caching::Actions::ActionCachePath.new(
				self,
				main_app.url_for(contentable),
				false
			).path)
		end

	end
end
