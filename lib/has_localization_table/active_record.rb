module HasLocalizationTable
  module ActiveRecord
    def has_localization_table(*args)
      options = args.extract_options!
      options[:association_name] = args.first
      
      class_attribute :localization_table_options
      self.localization_table_options = options
      
      extend(ClassMethods)
      include(InstanceMethods)
    end
  end
end