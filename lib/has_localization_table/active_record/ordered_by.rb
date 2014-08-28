module HasLocalizationTable
  module ActiveRecord
    module OrderedBy
      def method_missing(name, *args, &block)
        if name.to_s =~ /\Aordered_by_([a-z0-9_]+)\Z/
          attribute = $1.to_sym
          return ordered_by_localized_attribute(attribute, *args) if localized_attributes.include?(attribute)
        end
        
        super
      end
      
      def respond_to?(*args)
        if args.first.to_s =~ /\Aordered_by_([a-z0-9_]+)\Z/
          return true if localized_attributes.include?($1.to_sym)
        end
        
        super
      end
      
    private
      # Order records by localization value
      def ordered_by_localized_attribute(attribute, asc = true, locale = HasLocalizationTable.current_locale)
        if locale != HasLocalizationTable.primary_locale
          with_localizations.order(<<-EOQ)
            COALESCE(
              #{localization_class.table_name}.#{attribute}, (
                SELECT #{attribute}
                FROM #{localization_class.table_name}
                WHERE #{reflect_on_association(localization_association_name).foreign_key} = #{self.table_name}.id
                  AND #{HasLocalizationTable.locale_foreign_key} = #{HasLocalizationTable.primary_locale.id}
              )
            ) #{asc ? "ASC" : "DESC"}
          EOQ
        else
          with_localizations.order("#{localization_class.table_name}.#{attribute} #{asc ? "ASC" : "DESC"}")
        end
      end
    end
  end
end