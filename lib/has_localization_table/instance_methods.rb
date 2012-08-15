module HasLocalizationTable
  module InstanceMethods
    def read_localized_attribute(attribute, locale = HasLocalizationTable.current_locale)
      attribute_cache[attribute.to_sym][locale.id] ||= localization_association.detect{ |a| a.send(HasLocalizationTable.locale_foreign_key) == locale.id }.send(attribute) rescue nil
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
            return read_localized_attribute($1, args.first) || read_localized_attribute($1, HasLocalizationTable.primary_locale)
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
    # Add localization objects for any available locale that doesn't have one 
    def build_missing_localizations!
      locale_ids = HasLocalizationTable.all_locales.map(&:id)
      HasLocalizationTable.all_locales.each do |l|
        unless localization_association.detect{ |str| str.send(HasLocalizationTable.locale_foreign_key) == l.id }
          localization_association.build(HasLocalizationTable.locale_foreign_key => l.id)
        end
        
        localization_association.sort_by!{ |l| locale_ids.index(l.send(HasLocalizationTable.locale_foreign_key)) || 0 }
      end
    end
    
    # Remove localization objects that are not filled in
    def reject_empty_localizations!
      localization_association.reject! { |l| !l.persisted? and localized_attributes.all?{ |attr| l.send(attr).blank? } }
    end
    
    # Helper method for getting the localization association without having to look up the name each time
    def localization_association
      @localization_association ||= begin
        association_name = localization_table_options[:association_name]
        send(association_name)
      end
    end
    
    def attribute_cache
      @localized_attribute_cache ||= localized_attributes.inject({}) { |memo, attr| memo[attr] = {}; memo }
    end
    
    def localized_attributes
      self.class.localized_attributes
    end
    
    def localization_table_options
      self.class.localization_table_options
    end
  end
end