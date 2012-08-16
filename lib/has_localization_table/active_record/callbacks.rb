module HasLocalizationTable
  module ActiveRecord
    module Callbacks
      def setup_localization_callbacks!
        # Initialize string records after main record initialization
        after_initialize do
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
    end
  end
end