require 'spec_helper'

describe HasLocalizationTable do
  describe '.with_options' do
    before do
      HasLocalizationTable.configure do |c|
        c.locale_class = 'Locale'
      end
    end

    it 'should make the options available within the block' do
      HasLocalizationTable.with_options(locale_class: 'Language') do
        HasLocalizationTable.locale_class.must_equal 'Language'
      end
    end

    it 'should revert to the original option values after the block' do
      HasLocalizationTable.with_options(locale_class: 'Language') {}
      HasLocalizationTable.locale_class.must_equal 'Locale'
    end
  end
end