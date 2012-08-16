module HasLocalizationTable
  module ActiveRecord
    module Relation
      def self.extended(klass)
        klass.send(:include, InstanceMethods)
        
        # Alias the scoping method to use the actual association name
        alias_method :"with_#{klass.localization_association_name}", :with_localizations
      end
      
      def with_localizations
        lcat = localization_class.arel_table
        
        scoped.joins(
          arel_table.join(lcat, Arel::Nodes::OuterJoin).
            on(lcat[:"#{self.name.underscore}_id"].eq(arel_table[self.primary_key]).and(lcat[HasLocalizationTable.locale_foreign_key].eq(HasLocalizationTable.current_locale.id))).
            join_sql
        )
      end
    
      def create_localization_association!
        self.has_many localization_association_name, localization_table_options.except(:association_name, :required, :optional)
      end
      private :create_localization_association!
      
      module InstanceMethods
        # Add localization objects for any available locale that doesn't have one 
        def build_missing_localizations!
          locale_ids = HasLocalizationTable.all_locales.map(&:id)
          HasLocalizationTable.all_locales.each do |locale|
            unless localization_association.detect{ |str| str.send(HasLocalizationTable.locale_foreign_key) == locale.id }
              localization_association.build(HasLocalizationTable.locale_foreign_key => locale.id)
            end
            
            localization_association.sort_by!{ |l| locale_ids.index(l.send(HasLocalizationTable.locale_foreign_key)) || 0 }
          end
        end
        
        # Remove localization objects that are not filled in
        def reject_empty_localizations!
          localization_association.reject! { |l| !l.persisted? and localized_attributes.all?{ |attr| l.send(attr).blank? } }
        end
      end
    end
  end
end