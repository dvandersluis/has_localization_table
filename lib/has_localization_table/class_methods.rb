module HasLocalizationTable
  module ClassMethods
    def self.extended(klass)
      klass.class_eval do
        create_localization_association!
        
        # Initialize string records after main record initialization
        after_initialize do
          build_missing_localizations!
        end
        
        before_validation do
          reject_empty_localizations!
          build_missing_localizations!
        end
        
        # Reject any blank strings before saving the record
        # Validation will have happened by this point, so if there is a required string that is needed, it won't be rejected
        before_save do
          reject_empty_localizations!
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
      
      klass.localized_attributes.each do |attribute|
        # Add validation to make all string fields required for the primary locale
        klass.send(:localization_class).class_eval do
          validates attribute, presence: { message: :custom_this_field_is_required },
            if: proc { |model| klass.name.constantize.localized_attribute_required?(attribute) && model.send(HasLocalizationTable.locale_foreign_key) == HasLocalizationTable.current_locale.id }
        end
      end
      
      # Alias the scoping method to use the actual association name
      alias_method :"with_#{klass.localization_association_name}", :with_localizations
    end
    
    def localization_class
      localization_table_options[:class_name].constantize
    end
    
    def localization_association_name
      localization_table_options[:association_name]
    end
    
    def localized_attributes
      # Determine which attributes of the association model should be accessable through the base class
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
    
    def method_missing(name, *args, &block)
      if name.to_s =~ /\Afind_by_([a-z0-9_]+(_and_[a-z0-9_]+)*)\Z/
        attributes = $1.split("_and_").map(&:to_sym)
        if (attributes & localized_attributes).size == attributes.size
          raise ArgumentError, "expected #{attributes.size} #{"argument".pluralize(attributes.size)}: #{attributes.join(", ")}" unless args.size == attributes.size
          args = attributes.zip(args).inject({}) { |memo, (key, val)| memo[key] = val; memo }
          return find_by_localized_attributes(args)
        end
      elsif name.to_s =~ /\Aordered_by_([a-z0-9_]+)\Z/
        attribute = $1.to_sym
        return ordered_by_localized_attribute(attribute, *args) if localized_attributes.include?(attribute)
      end
      
      super
    end
    
    def respond_to?(*args)
      if args.first.to_s =~ /\Afind_by_([a-z0-9_]+(_and_[a-z0-9_]+)*)\Z/
        attributes = $1.split("_and_").map(&:to_sym)
        return true if (attributes & localized_attributes).size == attributes.size
      elsif args.first.to_s =~ /\Aordered_by_([a-z0-9_]+)\Z/
        return true if localized_attributes.include?($1.to_sym)
      end
      
      super
    end
    
    def with_localizations
      lcat = localization_class.arel_table
      
      scoped.joins(
        arel_table.join(lcat, Arel::Nodes::OuterJoin).
          on(lcat[:"#{self.name.underscore}_id"].eq(arel_table[self.primary_key]).and(lcat[HasLocalizationTable.locale_foreign_key].eq(HasLocalizationTable.current_locale.id))).
          join_sql
      )
    end
    
  private
    def create_localization_association!
      self.has_many localization_association_name, localization_table_options.except(:association_name, :required, :optional)
    end
    
    # Find a record by multiple localization values
    def find_by_localized_attributes(attributes, locale = HasLocalizationTable.current_locale)
      with_localizations.where(localization_class.table_name => attributes).first
    end
    
    # Order records by localization value
    def ordered_by_localized_attribute(attribute, asc = true, locale = HasLocalizationTable.current_locale)
      with_localizations.order("#{localization_class.table_name}.#{attribute} #{asc ? "ASC" : "DESC"}")
    end
  end
end