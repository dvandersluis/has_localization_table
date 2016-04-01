module HasLocalizationTable
  module ActiveRecord
    module Attributes
      LOCALIZED_ATTRIBUTE_REGEX = /\A(?<name>[a-z0-9_]+)(?<suffix>=|_changed\?)?\Z/i

      autoload :Cache, 'has_localization_table/active_record/attributes/cache'

      def read_localized_attribute(attribute, locale = HasLocalizationTable.current_locale, options = {})
        locale ||= HasLocalizationTable.current_locale

        localized_attribute_cache.get(attribute, locale) do
          attr = localization_for(locale).send(attribute) rescue ''
          attr ||= '' # if the attribute somehow is nil, change it to a blank string so we're always dealing with strings

          fallback = options.fetch(:fallback, HasLocalizationTable.config.fallback_locale)

          if fallback && attr.blank?
            fallback = fallback.call(self) if fallback.respond_to?(:call)

            return read_localized_attribute(attribute, fallback) unless fallback == locale
          end

          attr
        end
      end

      def write_localized_attribute(attribute, value, locale = HasLocalizationTable.current_locale)
        value = value.to_s
        localization = localization_for(locale) ||
          localization_association.build(HasLocalizationTable.locale_foreign_key => locale.id)

        localization.send(:"#{attribute}=", value)
        value.blank? ? localized_attribute_cache.clear(attribute, locale) : localized_attribute_cache.set(attribute, locale, value)
      end

      # Define attribute getters and setters
      def method_missing(name, *args, &block)
        match = name.to_s.match(LOCALIZED_ATTRIBUTE_REGEX)

        if match
          if localized_attributes.include?(match[:name].to_sym)
            if match[:suffix].nil? # No equals sign -- not a setter
              # Try to load a string for the given locale
              # If that fails, try for the primary locale
              raise ArgumentError, "wrong number of arguments (#{args.size} for 0 or 1)" unless args.size.between?(0, 1)
              options = args.extract_options!
              return read_localized_attribute($1, args.first, options) || read_localized_attribute($1, HasLocalizationTable.primary_locale, options)
            elsif match[:suffix] == '='
              raise ArgumentError, "wrong number of arguments (#{args.size} for 1)" unless args.size == 1
              return write_localized_attribute($1, args.first)
            elsif current_localization.respond_to?(name).inspect
              return localized_attribute_changed?(name.to_s.sub(/_changed\?/, ''))
            end
          end
        end

        super
      end

      def respond_to?(*args)
        match = args.first.to_s.match(LOCALIZED_ATTRIBUTE_REGEX)
        return true if match && localized_attributes.include?(match[:name].to_sym)
        super
      end

      def reset_localized_attribute_cache
        localized_attribute_cache.reset
      end

    private

      def localized_attribute_cache
        @localization_attribute_cache ||= Cache.new(self)
      end

      def localized_attribute_changed?(attr)
        current_localization.send("#{attr}_changed?")
      end
    end
  end
end
