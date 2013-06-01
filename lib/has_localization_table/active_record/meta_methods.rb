module HasLocalizationTable
  module ActiveRecord
    module MetaMethods
      def self.extended(klass)
        klass.send(:include, InstanceMethods)
      end
      
      def localization_class
        localization_table_options[:class_name].constantize
      end
      
      def localization_association_name
        localization_table_options[:association_name]
      end
      
      def localized_attributes
        # Determine which attributes of the association model should be accessible through the base class
        # ie. everything that's not a primary key, foreign key, or timestamp attribute
        association_name = self.localization_table_options[:association_name] || :strings
        association = reflect_on_association(association_name)
        
        attribute_names = association.klass.attribute_names
        timestamp_attrs = association.klass.new.send(:all_timestamp_attributes_in_model).map(&:to_s)
        foreign_keys = association.klass.reflect_on_all_associations.map{ |a| a.association_foreign_key }
        primary_keys = [association.klass.primary_key]
        # protected_attrs = association.klass.protected_attributes.to_a
        
        (attribute_names - timestamp_attrs - foreign_keys - primary_keys).map(&:to_sym)
      end
      
      def localized_attribute_required?(attribute)
        return false unless localization_table_options[:required] || false
        return true unless localization_table_options[:optional]
        
        !localization_table_options[:optional].include?(attribute) 
      end
      
      module InstanceMethods
        # Helper method for getting the localization association without having to look up the name each time
        def localization_association
          association_name = localization_table_options[:association_name]
          send(association_name)
        end
        
        def localized_attributes
          self.class.localized_attributes
        end
        
        def localization_table_options
          self.class.localization_table_options
        end
      end
    end
  end
end