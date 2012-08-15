require 'active_support/configurable'
require 'active_support/inflector'

module HasLocalizationTable
  # Configures global settings for HasLocalizationTable
  #   HasLocalizationTable.configure do |config|
  #     config.default_locale = Locale.find_by_code("en")
  #   end
  def self.configure(&block)
    yield @config ||= HasLocalizationTable::Configuration.new
  end

  # Global settings for ODF::Converter
  def self.config
    @config
  end

  # need a Class for 3.0
  class Configuration #:nodoc:
    include ActiveSupport::Configurable
    include ActiveSupport::Inflector
    
    config_accessor :locale_class
    config_accessor :locale_foreign_key
    config_accessor :primary_locale
    config_accessor :current_locale
    config_accessor :all_locales
    config_accessor :class_suffix
    config_accessor :default_association_name
  end

  # this is ugly. why can't we pass the default value to config_accessor...?
  configure do |config|
    config.locale_class = "Locale"
    config.locale_foreign_key = "locale_id"
    config.class_suffix = "Localization"
    config.default_association_name = :localizations
    config.primary_locale = ->{ config.locale_class.constantize.first }
    config.current_locale = ->{ config.locale_class.constantize.first }
    config.all_locales = ->{ config.locale_class.constantize.all }
  end
end