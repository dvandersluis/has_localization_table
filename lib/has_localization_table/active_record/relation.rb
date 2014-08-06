module HasLocalizationTable
  module ActiveRecord
    module Relation
      def self.extended(klass)
        klass.send(:include, InstanceMethods)
        klass.send(:create_localization_associations!)

        # Alias the scoping method to use the actual association name
        alias_method :"with_#{klass.localization_association_name}", :with_localizations
      end
      
      def with_localizations(locale = HasLocalizationTable.current_locale.id)
        lcat = localization_class.arel_table
        
        scoped.joins(
          arel_table.join(lcat, Arel::Nodes::OuterJoin).
            on(lcat[:"#{self.name.underscore}_id"].eq(arel_table[self.primary_key]).and(lcat[HasLocalizationTable.locale_foreign_key].eq(locale))).
            join_sql
        )
      end

    private

      def create_localization_associations!
        create_has_many_association

        # if caller explicitly asked not to create a has_one association, there's nothing more to do
        return unless localization_table_options.fetch(:has_one, true)

        create_has_one_association if localization_table_options[:has_one] or HasLocalizationTable.create_has_one_by_default
      end

      # Collect the localization for the current locale
      def create_has_one_association
        table_name = localization_class.table_name
        foreign_key = HasLocalizationTable.locale_foreign_key
        association_name = localization_association_name.to_s.singularize.to_sym
        association_name = :localization if localized_attributes.include?(association_name)

        has_one_options = localization_table_options.except(:association_name, :required, :optional, :dependent, :has_one).
          merge({ conditions: Proc.new { "#{table_name}.#{foreign_key} = #{HasLocalizationTable.current_locale.id}"} })

        self.has_one association_name, has_one_options
        self.has_one(:localization, has_one_options) unless association_name == :localization
      end

      # Collect all localizations for the object
      def create_has_many_association
        self.has_many localization_association_name, localization_table_options.except(:association_name, :required, :optional, :has_one).reverse_merge(autosave: true) do
          def for_locale(locale)
            # where(HasLocalizationTable.locale_foreign_key => locale).first
            select{ |s| s.send(HasLocalizationTable.locale_foreign_key) == locale }.first
          end
        end
      end

    public

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