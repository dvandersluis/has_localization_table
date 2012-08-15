module HasLocalizationTable
  module ActiveRecord
    def has_localization_table(*args)
      options = args.extract_options!
      options[:association_name] = args.first || HasLocalizationTable.default_association_name
      
      class_attribute :localization_table_options
      self.localization_table_options = { dependent: :delete_all, class_name: localization_class.name }.merge(options)
      
      extend(ClassMethods)
      include(InstanceMethods)
    end
    
    def localization_class
      (self.name + HasLocalizationTable.class_suffix).constantize
    end
  end
end