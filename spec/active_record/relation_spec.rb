require 'spec_helper'

describe HasLocalizationTable do
  before do
    # Configure HLT
    HasLocalizationTable.configure do |c|
      c.primary_locale = Locale.first 
      c.current_locale = Locale.first
      c.all_locales = Locale.all
    end

    Object.send(:remove_const, :Article) rescue nil
    Article = Class.new(ActiveRecord::Base)
  end
  
  it "should alias with_localizations with the actual association name" do
    Article.has_localization_table :strings
    assert Article.respond_to? :with_strings
  end
end