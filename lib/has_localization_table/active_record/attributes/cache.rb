module HasLocalizationTable
  module ActiveRecord
    module Attributes
      class Cache < Hash
        attr_reader :klass

        def initialize(klass)
          @klass = klass
          reset
        end

        def get(attr, locale)
          clear(attr, locale) if changed?(attr, locale)
          self[attr.to_sym][locale.id] ||= yield
        end

        def set(attr, locale, value)
          self[attr.to_sym][locale.id] = value
        end

        def clear(attr, locale)
          self[attr.to_sym].delete(locale.id)
        end

        def reset
          replace(klass.localized_attributes.inject({}) { |memo, attr| memo[attr] = {}; memo })
        end

        def changed?(attr, locale)
          localization = klass.localization_for(locale)
          return false unless localization

          localization.send(attr) != self[attr.to_sym][locale.id]
        end
      end
    end
  end
end
