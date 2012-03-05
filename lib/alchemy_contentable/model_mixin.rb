# encoding: UTF-8
module AlchemyContentable
  module ModelMixin
    extend ActiveSupport::Concern

    RESERVED_URLNAMES = %w(admin messages)

    def self.included(model)
      model.stampable

      model.has_many :cells, :as => :contentable, :dependent => :destroy, :class_name => 'Alchemy::Cell'
      model.has_many :elements, :as => :contentable, :dependent => :destroy, :order => :position, :class_name => 'Alchemy::Element'

      model.has_many :to_be_sweeped_elements, :through => :sweeped_contentables,
                     :class_name => 'Alchemy::Element', :source => :element, :uniq => true
      model.has_many :sweeped_contentables, :as => :contentable, :class_name => 'Alchemy::SweepedContentables'

      require 'alchemy_contentable/patches/element'
      Alchemy::Element.add_contentable_type(model)
      # load it once to make active...
      model.new

      model.validates_presence_of :name, :message => '^' + I18n.t("please enter a name")
      model.validates_presence_of :page_layout, :message => '^' + I18n.t("Please choose a page layout."), :unless => :systempage?

      model.send :attr_accessor, :do_not_autogenerate
      model.send :attr_accessor, :do_not_sweep
      model.send :attr_accessor, :do_not_validate_language

      #model.before_save :set_title, :unless => proc { |contentable| contentable.systempage? || contentable.redirects_to_external? }
      #model.before_save :set_language_code, :unless => :systempage?
      #model.before_save :set_restrictions_to_child_pages, :if => proc { |contentable| !contentable.systempage? && contentable.restricted_changed? }
      #model.before_save :inherit_restricted_status, :if => proc { |contentable| !contentable.systempage? && contentable.parent && contentable.parent.restricted? }
      #model.after_create :autogenerate_elements, :unless => proc { |contentable| contentable.systempage? || contentable.do_not_autogenerate }
      #model.after_create :create_cells, :unless => :systempage?

    end


    module ClassMethods

      def not_locked
        where(:locked => false)
      end

      def published
        where(:public => true)
      end

      def accessable
        where(:restricted => false)
      end

      def restricted
        where(:restricted => true)
      end

      def not_restricted
        accessable
      end

      def all_last_edited_from(user)
        where(:updater_id => user.id).order('`alchemy_pages`.`updated_at` DESC').limit(5)
      end

      def flushables
        not_locked.published.contentpages
      end

      def searchables
        not_restricted.published.contentpages
      end

      def all_locked
        where(:locked => true)
      end

      def all_locked_by(user)
        where(:locked => true, :locked_by => user.id)
      end

      # Creates a copy of source (a self.class object) and does a copy of all elements depending to source.
      # You can pass any kind of Page#attributes as a difference to source.
      # Notice: It prevents the element auto_generator from running.
      def self.copy(source, differences = {})
        attributes = source.attributes.symbolize_keys.merge(differences)
        attributes.merge!(
          :do_not_autogenerate => true,
          :do_not_sweep => true,
          :visible => false,
          :public => false,
          :locked => false,
          :locked_by => nil
        )
        page = self.new(attributes.except(:id, :updated_at, :created_at, :created_id, :updater_id, :lft, :rgt, :depth))
        if page.save
          # copy the page´s cells
          source.cells.each do |cell|
            new_cell = Cell.create(:name => cell.name, :page_id => page.id)
          end
          # copy the page´s elements
          source.elements.each do |element|
            # detect cell for element
            # if cell is nil also pass nil to element.cell_id
            cell = nil
            cell = page.cells.detect { |c| c.name == element.cell.name } if element.cell
            new_element = Element.copy(element, :page_id => page.id, :cell_id => (cell.blank? ? nil : cell.id))
            new_element.move_to_bottom
          end
          return page
        else
          raise page.errors.full_messages
        end
      end
    end


    def urlname
      self.id
    end
    def visible
      true
    end
    def restricted
      false
    end
    def layoutpage?
      false
    end

    # Finds selected elements from page.
    #
    # Options are:
    #
    #     :only => Array of element names    # Returns only elements with given names
    #     :except => Array of element names  # Returns all elements except the ones with given names
    #     :count => Integer                  # Limit the count of returned elements
    #     :offset => Integer                 # Starts with an offset while returning elements
    #     :random => Boolean                 # Returning elements randomly shuffled
    #     :from_cell => Cell                 # Returning elements from given cell
    #
    # Returns only public elements by default.
    # Pass true as second argument to get all elements.
    #
    def find_selected_elements(options = {}, show_non_public = false)
      if options[:from_cell].class.name == 'Alchemy::Cell'
        elements = options[:from_cell].elements
      else
        elements = self.elements.not_in_cell
      end
      if !options[:only].blank?
        elements = self.elements.named(options[:only])
      elsif !options[:except].blank?
        elements = self.elements.excluded(options[:except])
      end
      elements = elements.offset(options[:offset]).limit(options[:count])
      elements = elements.order("RAND()") if options[:random]
      if show_non_public
        elements
      else
        elements.published
      end
    end

    def find_elements(options = {}, show_non_public = false) #:nodoc:
                                                             # TODO: What is this? A Kind of proxy method? Why not rendering the elements directly if you already have them????
      if !options[:collection].blank? && options[:collection].is_a?(Array)
        return options[:collection]
      else
        find_selected_elements(options, show_non_public)
      end
    end

    # Returns all elements that should be feeded via rss.
    #
    # Define feedable elements in your +page_layouts.yml+:
    #
    #   - name: news
    #     feed: true
    #     feed_elements: [element_name, element_2_name]
    #
    def feed_elements
      elements.find_all_by_name(definition['feed_elements'])
    end

    def elements_grouped_by_cells
      group = ::ActiveSupport::OrderedHash.new
      self.cells.each { |cell| group[cell] = cell.elements.not_trashed }
      if element_names_not_in_cell.any?
        group[Cell.new({:name => 'for_other_elements'})] = elements.not_trashed.not_in_cell
      end
      return group
    end

    def element_names_from_cells
      cell_definitions.collect { |c| c['elements'] }.flatten.uniq
    end

    def element_names_not_in_cell
      layout_description['elements'].uniq - element_names_from_cells
    end

    # Finds the previous page on the same structure level. Otherwise it returns nil.
    # Options:
    # => :restricted => boolean (standard: nil) - next restricted page (true), skip restricted pages (false), ignore restriction (nil)
    # => :public => boolean (standard: true) - next public page (true), skip public pages (false)
    def previous_page(options = {})
      default_options = {
        :restricted => nil,
        :public => true
      }
      options = default_options.merge(options)
      find_next_or_previous_page("previous", options)
    end

    # Finds the next page on the same structure level. Otherwise it returns nil.
    # Options:
    # => :restricted => boolean (standard: nil) - next restricted page (true), skip restricted pages (false), ignore restriction (nil)
    # => :public => boolean (standard: true) - next public page (true), skip public pages (false)
    def next_page(options = {})
      default_options = {
        :restricted => nil,
        :public => true
      }
      options = default_options.merge(options)
      find_next_or_previous_page("next", options)
    end

    def find_first_public(page)
      if (page.public == true)
        return page
      end
      page.children.each do |child|
        result = find_first_public(child)
        if (result!=nil)
          return result
        end
      end
      return nil
    end

    def name_entered?
      !self.name.blank?
    end

    def urlname_entered?
      !self.urlname.blank?
    end

    def set_url_name
      self.urlname = convert_url_name((self.urlname.blank? ? self.name : self.urlname))
    end

    def set_title
      self.title = self.name
    end

    def show_in_navigation?
      if visible?
        return true
      end
      return false
    end

    def lock(user)
      self.locked = true
      self.locked_by = user.id
      self.save(:validate => false)
    end

    def unlock
      self.locked = false
      self.locked_by = nil
      self.do_not_sweep = true
      self.save
    end

    def public_elements
      self.elements.select { |m| m.public? }
    end

    # Returns the name of the creator of this page.
    def creator
      @page_creator ||= Alchemy::User.find_by_id(creator_id)
      return I18n.t('unknown') if @page_creator.nil?
      @page_creator.name
    end

    # Returns the name of the last updater of this page.
    def updater
      @page_updater = Alchemy::User.find_by_id(updater_id)
      return I18n.t('unknown') if @page_updater.nil?
      @page_updater.name
    end

    # Returns the name of the user currently editing this page.
    def current_editor
      @current_editor = Alchemy::User.find_by_id(locked_by)
      return I18n.t('unknown') if @current_editor.nil?
      @current_editor.name
    end

    def locker
      Alchemy::User.find_by_id(self.locked_by)
    end

    def fold(user_id, status)
      folded_page = Alchemy::FoldedPage.find_or_create_by_user_id_and_page_id(user_id, self.id)
      folded_page.update_attributes(:folded => status)
      folded_page.save
    end

    def folded?(user_id)
      folded_page = Alchemy::FoldedPage.find_by_user_id_and_page_id(user_id, self.id)
      return false if folded_page.nil?
      folded_page.folded
    end

    def elements_by_type type
      elements.select { |m| type.include? m.name }
    end

    # Returns the translated explanation of seven the page stati.
    # TODO: Let I18n do this!
    def humanized_status
      case self.status
        when 0
          return I18n.t('page_status_visible_public_locked')
        when 1
          return I18n.t('page_status_visible_unpublic_locked')
        when 2
          return I18n.t('page_status_invisible_public_locked')
        when 3
          return I18n.t('page_status_invisible_unpublic_locked')
        when 4
          return I18n.t('page_status_visible_public')
        when 5
          return I18n.t('page_status_visible_unpublic')
        when 6
          return I18n.t('page_status_invisible_public')
        when 7
          return I18n.t('page_status_invisible_unpublic')
      end
    end

    # Returns the status code. Used by humanized_status and the page status icon inside the sitemap rendered by Pages.index.
    def status
      if self.locked
        if self.public? && self.visible?
          return 0
        elsif !self.public? && self.visible?
          return 1
        elsif self.public? && !self.visible?
          return 2
        elsif !self.public? && !self.visible?
          return 3
        end
      else
        if self.public? && self.visible?
          return 4
        elsif !self.public? && self.visible?
          return 5
        elsif self.public? && !self.visible?
          return 6
        elsif !self.public? && !self.visible?
          return 7
        end
      end
    end

    def has_controller?
      !Alchemy::PageLayout.get(self.page_layout).nil? && !Alchemy::PageLayout.get(self.page_layout)["controller"].blank?
    end

    def controller_and_action
      if self.has_controller?
        {:controller => self.layout_description["controller"], :action => self.layout_description["action"]}
      end
    end

    # Returns the self#page_layout description from config/alchemy/page_layouts.yml file.
    def layout_description
      return {} if self.systempage?
      description = Alchemy::PageLayout.get(self.page_layout)
      if description.nil?
        raise "Description could not be found for page layout named #{self.page_layout}. Please check page_layouts.yml file."
      else
        description
      end
    end

    alias_method :definition, :layout_description

    def cell_definitions
      cell_names = self.layout_description['cells']
      return [] if cell_names.blank?
      Cell.all_definitions_for(cell_names)
    end

    # Returns translated name of the pages page_layout value.
    # Page layout names are defined inside the config/alchemy/page_layouts.yml file.
    # Translate the name in your config/locales language yml file.
    def layout_display_name
      I18n.t("alchemy.page_layout_names.#{page_layout}", :default => page_layout.camelize)
    end

    def renamed?
      self.name_was != self.name || self.urlname_was != self.urlname
    end

    def changed_publicity?
      self.public_was != self.public
    end

    def set_restrictions_to_child_pages
      descendants.each do |child|
        child.update_attribute(:restricted, self.restricted?)
      end
    end

    def inherit_restricted_status
      self.restricted = parent.restricted?
    end

    def contains_feed?
      definition["feed"]
    end

    # Returns true or false if the pages layout_description for config/alchemy/page_layouts.yml contains redirects_to_external: true
    def redirects_to_external?
      definition["redirects_to_external"]
    end


    # Returns true or false if the page has a page_layout that has cells.
    def can_have_cells?
      !definition['cells'].blank?
    end

    def has_cells?
      cells.any?
    end

    def self.link_target_options
      options = [
        [I18n.t('default', :scope => :link_target_options), '']
      ]
      link_target_options = Config.get(:link_target_options)
      link_target_options.each do |option|
        options << [I18n.t(option, :scope => :link_target_options), option]
      end
      options
    end

    def locker_name
      return I18n.t('unknown') if self.locker.nil?
      self.locker.name
    end

    def rootpage?
      true
    end

    def systempage?
      false
    end

    def self.rootpage
      self.root
    end

    private

    def find_next_or_previous_contentable(direction = "next", options = {})
      if direction == "previous"
        step_direction = ["#{resource_handler.model_name}.lft < ?", self.lft]
        order_direction = "lft DESC"
      else
        step_direction = ["#{resource_handler.model_name}.lft > ?", self.lft]
        order_direction = "lft"
      end
      conditions = resource_handler.model.merge_conditions(
        {:parent_id => self.parent_id},
        {:public => options[:public]},
        step_direction
      )
      if !options[:restricted].nil?
        conditions = resource_handler.model.merge_conditions(conditions, {:restricted => options[:restricted]})
      end
      resource_handler.model.where(conditions).order(order_direction).limit(1)
    end

    # Converts the given nbame into an url friendly string
    # Names shorter than 3 will be filled with dashes, so it does not collidate with the language code.
    def convert_url_name(name)
      url_name = name.gsub(/[äÄ]/, 'ae').gsub(/[üÜ]/, 'ue').gsub(/[öÖ]/, 'oe').parameterize
      url_name = ('-' * (3 - url_name.length)) + url_name if url_name.length < 3
      return url_name
    end

    # Looks in the layout_descripion, if there are elements to autogenerate.
    # If so, it generates them.
    def autogenerate_elements
      elements = self.layout_description["autogenerate"]
      unless (elements.blank?)
        elements.each do |element|
          element = Alchemy::Element.create_from_scratch({'page_id' => self.id, 'name' => element})
          element.move_to_bottom if element
        end
      end
    end

    def create_cells
      return false if !can_have_cells?
      definition['cells'].each do |cellname|
        cells.create({:name => cellname})
      end
    end
  end
end