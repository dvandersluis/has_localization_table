module HasLocalizationTable
  module ActiveRecord
    module Attributes
      def read_localized_attribute(attribute, locale = HasLocalizationTable.current_locale, options = {})
        locale ||= HasLocalizationTable.current_locale

        attribute_cache[attribute.to_sym][locale.id] ||= begin
          attr = localization_association.detect{ |a| a.send(HasLocalizationTable.locale_foreign_key) == locale.id }.send(attribute) rescue nil
          if options.fetch(:fallback, HasLocalizationTable.config.fallback_locale) && !attr
            fallback = options.fetch(:fallback, HasLocalizationTable.config.fallback_locale)
            fallback = fallback.call(self) if fallback.respond_to?(:call)
            attr = read_localized_attribute(attribute, fallback)
          end
          attr
        end
      end
      
      def write_localized_attribute(attribute, value, locale = HasLocalizationTable.current_locale)
        value = value.to_s
        localization = localization_association.detect{ |a| a.send(HasLocalizationTable.locale_foreign_key) == locale.id } ||
          localization_association.build(HasLocalizationTable.locale_foreign_key => locale.id)
        
        localization.send(:"#{attribute}=", value)
        attribute_cache[attribute.to_sym][locale.id] = value.blank? ? nil : value
      end
      
      # Define attribute getters and setters
      def method_missing(name, *args, &block)
        if name.to_s =~ /\A([a-z0-9_]+)(=)?\Z/i
          if localized_attributes.include?($1.to_sym)
            if $2.nil? # No equals sign -- not a setter
              # Try to load a string for the given locale
              # If that fails, try for the primary locale
              raise ArgumentError, "wrong number of arguments (#{args.size} for 0 or 1)" unless args.size.between?(0, 1)
              options = args.extract_options!
              return read_localized_attribute($1, args.first, options) || read_localized_attribute($1, HasLocalizationTable.primary_locale, options)
            else
              raise ArgumentError, "wrong number of arguments (#{args.size} for 1)" unless args.size == 1
              return write_localized_attribute($1, args.first)
            end
          end
        end
        
        super
      end
      
      def respond_to?(*args)
        return true if args.first.to_s =~ /\A([a-z0-9_]+)=?\Z/i and localized_attributes.include?($1.to_sym)
        super
      end
    
    private
      def attribute_cache
        @localization_attribute_cache ||= localized_attributes.inject({}) { |memo, attr| memo[attr] = {}; memo }
      end
    end
  end
end