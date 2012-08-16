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
    Article.has_localization_table
  end
  
  let(:a) { Article.new(name: "Test", description: "Description") }
  
  it "should set localized attributes" do
    a.localizations.first.name.must_equal "Test"
    a.localizations.first.description.must_equal "Description"
  end
  
  it "should create accessor methods" do
    a.name.must_equal "Test"
    a.description.must_equal "Description"
  end
  
  it "should save localized attributes" do
    a.save!
    a.reload
    a.name.must_equal "Test"
    a.description.must_equal "Description"
  end
  
  it "should create mutator methods" do
    a.name = "Changed"
    a.description = "Changed Description"
    a.name.must_equal "Changed"
    a.description.must_equal "Changed Description"
    a.localizations.first.name.must_equal "Changed"
    a.localizations.first.description.must_equal "Changed Description"
  end
  
  it "should use the current locale when setting" do
    a
    
    HasLocalizationTable.configure do |c|
      c.current_locale = Locale.last
    end
    
    a.name = "French Name"
    a.description = "French Description"
    
    eng = a.localizations.detect{ |s| s.locale_id == Locale.first.id }
    fre = a.localizations.detect{ |s| s.locale_id == Locale.last.id }
    
    eng.name.must_equal "Test"
    eng.description.must_equal "Description"
    fre.name.must_equal "French Name"
    fre.description.must_equal "French Description"
  end
end