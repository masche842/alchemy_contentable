Alchemy::Element.class_eval do

  attr_accessible(
    :contentable_type,
    :contentable_id,
    :cell_id,
    :create_contents_after_create,
    :folded,
    :name,
    :page_id,
    :position,
    :public,
    :unique
  )

  # All Elements inside a cell are a list. All Elements not in cell are in the cell_id.nil list.
  acts_as_list :scope => [:page_id, :cell_id, :contentable_id, :contentable_type]

  # Remove all Alchemy validations and replace them in order to scope uniqueness of position to contentable
  reset_callbacks :validate
  validates_presence_of :name, :on => :create

  belongs_to :contentable, :polymorphic => true

  def self.contentable_identifier(contentable_class)
    contentable_class.name.underscore.split('/').last.pluralize
  end

  has_many :sweeped_contentables, :class_name => 'Alchemy::SweepedContentables'

  def self.add_contentable_type(contentable_class)
    contentable_type = contentable_class.name
    has_many :"to_sweep_#{contentable_identifier(contentable_class)}", :through => :sweeped_contentables,
      :uniq => true, :source => :contentable, :source_type => contentable_type
    Alchemy::ContentablesSweeper.send(:observe, contentable_class)
  end

  # TODO: add a trashed column to elements table
  scope :trashed, where(:page_id => nil, :contentable_id => nil).order('updated_at DESC')
  scope :not_trashed, where('`alchemy_elements`.`page_id` IS NOT NULL OR `alchemy_elements`.`contentable_id` IS NOT NULL')
  scope :all_siblings, lambda { |element|
    element.page ? where(:page => self.page) : where(:contentable_id => self.contentable_id, :contentable_type => self.contentable_type) }

  # List all elements for page_layout
  def self.all_for_page(page)
    raise TypeError unless page
    # if page_layout has cells, collect elements from cells and group them by cellname
    page_layout = Alchemy::PageLayout.get(page.page_layout)
    if page_layout.blank?
      logger.warn "\n++++++\nWARNING! Could not find page_layout description for page: #{page.name}\n++++++++\n"
      return []
    end
    elements_for_layout = []
    elements_for_layout += all_definitions_for(page_layout['elements'])
    return [] if elements_for_layout.blank?
    # all unique and limited elements from this layout
    limited_elements = elements_for_layout.select{ |m| m["unique"] == true || (m["amount"] > 0 unless m["amount"].nil?) }
    elements_already_on_the_page = page.elements
    # delete all elements from the elements that could be placed that are unique or limited and already and the page
    elements_counts = Hash.new(0)
    elements_already_on_the_page.each { |e| elements_counts[e.name] += 1 }
    limited_elements.each do |limited_element|
      next if elements_counts[limited_element["name"]] == 0
      if limited_element["unique"]
        elements_for_layout.delete(limited_element) if elements_counts[limited_element["name"]] > 0
        next
      end
      unless limited_element["amount"].nil?
        elements_for_layout.delete(limited_element) if elements_counts[limited_element["name"]] >= limited_element["amount"]
      end
    end
    elements_for_layout
  end

  # Returns next Element on self.page or nil. Pass a Element.name to get next of this kind.
  def next(name = nil)
    #taken from acts_as_list
    elements = self.class.where("#{scope_condition} AND #{position_column} > #{send(position_column)}")
    elements = elements.published
    elements = elements.where(:name => name) if name
    elements.order("position ASC").limit(1).first
  end

  # Returns previous Element on self.page or nil. Pass a Element.name to get previous of this kind.
  def prev(name = nil)
    #taken from acts_as_list
    elements = self.class.where("#{scope_condition} AND #{position_column} < #{send(position_column)}").published
    elements = elements.published
    elements = elements.where(:name => name) if name
    elements.order("position DESC").limit(1).first
  end

  # Stores the page into `to_be_sweeped_pages` (Pages that have to be sweeped after updating element).
  def store_page(page)
    return true if page.nil?
    if page.is_a? Alchemy::Page
      unless self.to_be_sweeped_pages.include? page
        self.to_be_sweeped_pages << page
        self.save
      end
    else
      store_contentable(page)
    end
  end

  # Stores the contentable into `to_sweep_contentables` (Pages that have to be sweeped after updating element).
  def store_contentable(contentable)
    return true if contentable.nil? or not self.respond_to?("to_sweep_#{self.class.contentable_identifier(contentable.class)}".to_sym)
    unless self.send("to_sweep_#{self.class.contentable_identifier(contentable.class)}").include? contentable
      self.send("to_sweep_#{self.class.contentable_identifier(contentable.class)}") << contentable
      self.save
    end
  end

  def page_or_contentable=(contentable)
    if contentable.is_a? Alchemy::Page
      self.page = contentable
    else
      self.contentable = contentable
    end
  end

  def page_or_contentable
    self.page or self.contentable
  end

  # Nullifies the page_id and cell_id, fold the element, set it to unpublic and removes its position.
  def trash
    self.attributes = {
      :page_id => nil,
      :contentable_id => nil,
      :contentable_type => nil,
      :cell_id => nil,
      :folded => true,
      :public => false
    }
    self.remove_from_list
  end

  def trashed?
    page_id.nil? and contentable_id.nil?
  end

  # creates the contents for this element as described in the elements.yml
  # same as in origin, but public
  def create_contents
    contents = []
    if description["contents"].blank?
      logger.warn "\n++++++\nWARNING! Could not find any content descriptions for element: #{self.name}\n++++++++\n"
    else
      description["contents"].each do |content_hash|
        contents << Alchemy::Content.create_from_scratch(self, content_hash.symbolize_keys)
      end
    end
  end
end

Alchemy::Element.instance_eval do

  class << self
    alias_method :original_new_from_scratch, :new_from_scratch
  end

  # Builds a new element as described in +/config/alchemy/elements.yml+
  def new_from_scratch(attributes)
    element = original_new_from_scratch(attributes)
    element.contentable_id = attributes[:contentable_id]
    element.contentable_type = attributes[:contentable_type]
    element
  end
end

