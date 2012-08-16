module HasLocalizationTable
  module ActiveRecord
    def has_localization_table(*args)
      options = args.extract_options!
      options[:association_name] = args.first || HasLocalizationTable.default_association_name
      options[:class_name] = options[:class_name].name if options[:class_name].respond_to?(:name)
      
      class_attribute :localization_table_options
      self.localization_table_options = { dependent: :delete_all, class_name: self.name + HasLocalizationTable.class_suffix }.merge(options)
      
      extend(ClassMethods)
      include(InstanceMethods)
    end
  end
end