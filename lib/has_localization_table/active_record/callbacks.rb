module HasLocalizationTable
  module ActiveRecord
    module Callbacks
      def self.extended(klass)
        klass.send(:include, InstanceMethods)
      end

      def setup_localization_callbacks!
        # Initialize string records after main record initialization
        after_initialize(if: :add_localization_after_initialize?) do
          build_missing_localizations!
        end

        before_validation do
          reject_empty_localizations!
          build_missing_localizations!
        end

        # Reject any blank strings before saving the record
        # Validation will have happened by this point, so if there is a required string that is needed, it won't be rejected
        before_save do
          reject_empty_localizations!
        end
      end
      private :setup_localization_callbacks!

      module InstanceMethods
        def add_localization_after_initialize?
          localization_table_options.fetch(:initialize, true) && !localization_table_options.fetch(:include, false)
        end

        private :add_localization_after_initialize?
      end
    end
  end
end
