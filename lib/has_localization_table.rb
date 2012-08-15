require "has_localization_table/version"
require "has_localization_table/config"
require "has_localization_table/class_methods"
require "has_localization_table/instance_methods"
require "has_localization_table/active_record"

ActiveRecord::Base.extend(HasLocalizationTable::ActiveRecord) if defined?(ActiveRecord::Base)

module HasLocalizationTable
  HasLocalizationTable.config.config.keys.each do |key|
    define_singleton_method key do
      val = config.send(key)
      val = val.call if val.respond_to?(:call)
      val
    end
  end
end