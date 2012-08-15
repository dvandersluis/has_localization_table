module HasLocalizationTable
  module InstanceMethods
    # Both strings and the associations are memoized, so that if an association adds more than one attribute to the main model, the association doesn't need 
    # to be loaded each time a different attribute is accessed.
    def read_localized_attribute(locale, association, attribute)
      attribute_cache[attribute][locale.id] ||= localized_association.detect{ |a| a.send(HasLocalizationTable.config.locale_foreign_key) == locale.id }.send(attribute) rescue nil
    end
    
    def write_localized_attribute(locale, association, attribute, value)
      string = send(association).detect{ |a| a.send(HasLocalizationTable.config.locale_foreign_key) == locale.id } || send(association).build(HasLocalizationTable.config.locale_foreign_key => locale.id)
      value = value.to_s
      
      string.send(:"#{attribute}=", value)
      attribute_cache[attribute][locale.id] = value.blank? ? nil : value
    end
  
  private
    def localized_association
      @localized_association ||= begin
        association_name = self.class.localization_table_options[:association_name] || :strings
        send(association_name)
      end
    end
    
    def attribute_cache
      @localized_attribute_cache ||= self.class.localized_attributes.inject({}) { |memo, attr| memo[attr] = {}; memo }
    end
  end
end