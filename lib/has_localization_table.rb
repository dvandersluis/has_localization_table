require "has_localization_table/version"
require "has_localization_table/config"
require "has_localization_table/active_record"

ActiveRecord::Base.extend(HasLocalizationTable::ActiveRecord) if defined?(ActiveRecord::Base)

module HasLocalizationTable
  [:primary_locale, :current_locale, :all_locales].each do |meth|
    define_singleton_method meth do
      l = config.send(meth)
      return l.call if l.respond_to?(:call)
      l
    end
  end
end