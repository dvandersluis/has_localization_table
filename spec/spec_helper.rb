require 'minitest/autorun'
require 'active_record'
require 'has_localization_table'

class MiniTest::Spec
  def run(*args, &block)
    value = nil
 
    begin
      ActiveRecord::Base.connection.transaction do
        value = super
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
    end
 
    return value  # The result of run must be always returned for the pretty dots to show up
  end
end