require "has_localization_table/version"
require "has_localization_table/config"
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

  def self.with_options(options, &block)
    # Ugly but we need to make sure we don't clobber the existing configuration
    old_config = @config.dup
    old_config.instance_variable_set('@_config', @config.config.dup)

    @config.config.merge!(options.slice(*HasLocalizationTable.config.config.keys))

    yield

  ensure
    @config = old_config
  end
end