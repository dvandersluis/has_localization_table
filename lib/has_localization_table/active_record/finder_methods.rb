module HasLocalizationTable
  module ActiveRecord
    module FinderMethods
      def method_missing(name, *args, &block)
        if name.to_s =~ /\Afind_by_([a-z0-9_]+(_and_[a-z0-9_]+)*)\Z/
          attributes = $1.split("_and_").map(&:to_sym)
          if (attributes & localized_attributes).size == attributes.size
            raise ArgumentError, "expected #{attributes.size} #{"argument".pluralize(attributes.size)}: #{attributes.join(", ")}" unless args.size == attributes.size
            args = attributes.zip(args).inject({}) { |memo, (key, val)| memo[key] = val; memo }
            return find_by_localized_attributes(args)
          end
        end
        
        super
      end
      
      def respond_to?(*args)
        if args.first.to_s =~ /\Afind_by_([a-z0-9_]+(_and_[a-z0-9_]+)*)\Z/
          attributes = $1.split("_and_").map(&:to_sym)
          return true if (attributes & localized_attributes).size == attributes.size
        end
        
        super
      end
    
    private
      # Find a record by multiple localization values
      def find_by_localized_attributes(attributes, locale = HasLocalizationTable.current_locale)
        with_localizations.where(localization_class.table_name => attributes).first
      end
    end
  end
end