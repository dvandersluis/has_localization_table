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

  module ClassMethods
    def self.extended(klass)
      options = { dependent: :delete_all }.merge(klass.localization_table_options)
      
      association_name = options.delete(:association_name) || :strings
      
      # If class_name isn't explicitly defined, try adding String onto the current class name
      options[:class_name] = klass.name + "String" if options[:class_name].blank? and (Module.const_get(klass.name + "String") rescue false)
      
      # Define the association
      klass.has_many association_name, options.except(:required, :optional)
      association = klass.reflect_on_association(association_name)
      
      klass.class_eval do
        # Initialize string records after main record initialization
        after_initialize do
          build_missing_strings
        end
        
        before_validation do
          reject_empty_strings
          build_missing_strings
        end
        
        # Reject any blank strings before saving the record
        # Validation will have happened by this point, so if there is a required string that is needed, it won't be rejected
        before_save do
          reject_empty_strings
        end
        
        # Add validation to ensure a string for the primary locale exists if the string is required
        validate do
          if self.class.localization_table_options[:required] || false
            errors.add(association_name, :primary_lang_string_required) unless send(association_name).any? do |string|
              string.send(HasLocalizationTable.config.locale_foreign_key) == HasLocalizationTable.primary_locale.id
            end
          end
        end
        
        define_method :build_missing_strings do
          locale_ids = HasLocalizationTable.all_locales.map(&:id)
          HasLocalizationTable.all_locales.each do |l|
            send(association_name).build(HasLocalizationTable.config.locale_foreign_key => l.id) unless send(association_name).detect{ |str| str.send(HasLocalizationTable.config.locale_foreign_key) == l.id }
            send(association_name).sort_by!{ |s| locale_ids.index(s.send(HasLocalizationTable.config.locale_foreign_key)) || 0 }
          end
        end
        private :build_missing_strings
        
        define_method :reject_empty_strings do
          send(association_name).reject! { |s| !s.persisted? and self.class.localized_attributes.all?{ |attr| s.send(attr).blank? } }
        end
        private :reject_empty_strings
        
        # Find a record by multiple string values
        define_singleton_method :find_by_localized_attributes do |attributes, locale = HasLocalizationTable.current_locale|
          string_record = association.klass.where({ HasLocalizationTable.config.locale_foreign_key => locale.id }.merge(attributes)).first
          string_record.send(klass.to_s.underscore.to_sym) rescue nil
        end
        private_class_method :find_by_localized_attributes
      end
      
      klass.localized_attributes.each do |attribute|
        # Add validation to make all string fields required for the primary locale
        association.klass.class_eval do
          validates attribute, presence: { message: :custom_this_field_is_required },
            if: proc { |model| klass.name.constantize.localized_attribute_required?(attribute) && model.send(HasLocalizationTable.config.locale_foreign_key) == HasLocalizationTable.current_locale.id }
        end
      
        # Set up accessors and ordering named_scopes for each non-FK attribute on the base model
        klass.class_eval do
          define_method attribute do |locale = HasLocalizationTable.current_locale|
            # Try to load a string for the given locale
            # If that fails, try for the primary locale
            get_cached_localized_attribute(locale, association_name, attribute) || get_cached_localized_attribute(HasLocalizationTable.primary_locale, association_name, attribute)
          end
          
          define_method "#{attribute}=" do |value|
            cache_localized_attribute(HasLocalizationTable.current_locale, association_name, attribute, value)
          end
          
          define_singleton_method "ordered_by_#{attribute}" do |direction = :asc|
            direction = direction == :asc ? "ASC" : "DESC"
            
            joins(%{
              LEFT OUTER JOIN #{association.table_name}
                ON #{association.table_name}.#{association.foreign_key} = #{self.table_name}.#{self.primary_key}
                  AND #{association.table_name}.#{HasLocalizationTable.config.locale_foreign_key} = %d
              } % HasLocalizationTable.current_locale.id
            ).
            order( "#{association.table_name}.#{attribute} #{direction}")
            #order{ Squeel::Nodes::Order.new(Squeel::Nodes::Stub.new(association.table_name).send(attribute), direction) }
          end
        end
      end
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
        if (attributes & localized_attributes).size == attributes.size and args.size == attributes.size
          raise ArgumentError, "expected #{attributes.size} #{"argument".pluralize(attributes.size)}" unless args.size == attributes.size
          args = attributes.zip(args).inject({}) { |memo, (key, val)| memo[key] = val; memo }
          return find_by_localized_attributes(args)
        end
      end
      
      super
    end
    
    def respond_to?(*args)
      if args.first.to_s =~ /\Afind_by_([a-z0-9_]+(_and_[a-z0-9_]+)*)\Z/
        attributes = $1.split("_and_").map(&:to_sym)
        return ((attributes & localized_attributes).size == attributes.size)
      end
      
      super
    end
  end
  
  module InstanceMethods
  private
    # Both strings and the associations are memoized, so that if an association adds more than one attribute to the main model, the association doesn't need 
    # to be loaded each time a different attribute is accessed.
    def get_cached_localized_attribute(locale, association, attribute)
      @_localized_attribute_cache ||= {}
      @_localized_attribute_cache[attribute] ||= {}

      @_localized_association_cache ||= {}
      @_localized_association_cache[association] ||= {}
    
      @_localized_attribute_cache[attribute][locale.id] ||= begin
        @_localized_association_cache[association][locale.id] ||= send(association).detect{ |a| a.send(HasLocalizationTable.config.locale_foreign_key) == locale.id }
        s = @_localized_association_cache[association][locale.id].send(attribute) rescue nil
        s.blank? ? nil : s
      end
    end
    
    def cache_localized_attribute(locale, association, attribute, value)
      string = send(association).detect{ |a| a.send(HasLocalizationTable.config.locale_foreign_key) == locale.id } || send(association).build(HasLocalizationTable.config.locale_foreign_key => locale.id)
      value = value.to_s
      
      string.send(:"#{attribute}=", value)
      
      @_localized_attribute_cache ||= {}
      @_localized_attribute_cache[attribute] ||= {}
      @_localized_attribute_cache[attribute][locale.id] = value.blank? ? nil : value
    end
  end
end