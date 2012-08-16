module HasLocalizationTable
  module ActiveRecord
    module Validations
      def setup_localization_validations!
        localized_attributes.each do |attribute|
          # Add validation to make all string fields required for the primary locale
          obj = self
          localization_class.class_eval do
            validates attribute, presence: { message: :custom_this_field_is_required },
              if: proc { |model| obj.name.constantize.localized_attribute_required?(attribute) && model.send(HasLocalizationTable.locale_foreign_key) == HasLocalizationTable.current_locale.id }
          end
        end
        
        # Add validation to ensure a string for the primary locale exists if the string is required
        validate do
          if localization_table_options[:required] || false
            errors.add(localization_association_name, :primary_lang_string_required) unless localization_association.any? do |string|
              string.send(HasLocalizationTable.locale_foreign_key) == HasLocalizationTable.primary_locale.id
            end
          end
        end
      end
      private :setup_localization_validations!    
    end
  end
end