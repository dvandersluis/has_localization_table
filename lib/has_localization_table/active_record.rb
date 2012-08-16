module HasLocalizationTable
  module ActiveRecord
    autoload :Attributes,     'has_localization_table/active_record/attributes'
    autoload :Callbacks,      'has_localization_table/active_record/callbacks'
    autoload :FinderMethods,  'has_localization_table/active_record/finder_methods'
    autoload :MetaMethods,    'has_localization_table/active_record/meta_methods'
    autoload :OrderedBy,      'has_localization_table/active_record/ordered_by'
    autoload :Relation,       'has_localization_table/active_record/relation'
    autoload :Validations,    'has_localization_table/active_record/validations'
    
    def has_localization_table(*args)
      options = args.extract_options!
      options[:association_name] = args.first || HasLocalizationTable.default_association_name
      options[:class_name] = options[:class_name].name if options[:class_name].respond_to?(:name)
      
      class_attribute :localization_table_options
      self.localization_table_options = { dependent: :delete_all, class_name: self.name + HasLocalizationTable.class_suffix }.merge(options)
      
      extend Relation, FinderMethods, OrderedBy, Callbacks, Validations, MetaMethods
      include Attributes
      
      create_localization_association!
      setup_localization_callbacks!
      setup_localization_validations!
    end
  end
end