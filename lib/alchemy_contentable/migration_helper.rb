module AlchemyContentable
  module MigrationHelper
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def contentable
        column(:public, :boolean)
        column(:locked, :boolean)
        column(:locked_by, :boolean)
        column(:page_layout, :string)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, AlchemyContentable::MigrationHelper)
