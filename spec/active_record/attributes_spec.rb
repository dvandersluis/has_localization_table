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

  it "should save with update_attributes" do
    a.save!
    a.update_attributes!(name: "Test 2")
    Article.find(a.id).name.must_equal "Test 2"
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
  
  it "should return the correct value when the current locale changes" do
    Locale.class_eval { cattr_accessor :current }
    eng = Locale.find_by_name("English")
    fre = Locale.find_by_name("French")
    
    HasLocalizationTable.configure do |c|
      c.current_locale = ->{ Locale.current }
    end

    Locale.current = eng
    a.name = "English Name"
    a.description = "English Description"
    
    Locale.current = fre
    a.name = "French Name"
    a.description = "French Description"
    
    Locale.current = eng
    a.name.must_equal "English Name"
    a.description.must_equal "English Description"
    
    Locale.current = fre
    a.name.must_equal "French Name"
    a.description.must_equal "French Description"
  end
  
  it "should return the correct locale's value even if the cache is empty" do
    Locale.class_eval { cattr_accessor :current }
    Locale.current = eng = Locale.find_by_name("English")
    fre = Locale.find_by_name("French")
    
    HasLocalizationTable.configure do |c|
      c.current_locale = ->{ Locale.current }
    end

    a.localizations.last.attributes = { name: "French Name", description: "French Description" }
        
    # Force empty cache 
    a.instance_variable_set(:@localization_attribute_cache, { name: {}, description: {} })

    Locale.current = fre
    a.name.must_equal "French Name"
    a.description.must_equal "French Description"
  end
  
  it "should return the correct locale's value even if a language was added" do
    Locale.class_eval { cattr_accessor :current }
    Locale.current = eng = Locale.find_by_name("English")
    fre = Locale.find_by_name("French")
    
    HasLocalizationTable.configure do |c|
      c.current_locale = ->{ Locale.current }
      c.all_locales = [eng]
    end
    
    Object.send(:remove_const, :Article) rescue nil
    Article = Class.new(ActiveRecord::Base)
    Article.has_localization_table
    
    aa = Article.create!(name: "Name", description: "Description")
    l = ArticleLocalization.create!(article: aa, locale: fre, name: "French Name", description: "French Description")
    
    aa.reload
    
    Locale.current = fre
    aa.name.must_equal "French Name"
    aa.description.must_equal "French Description"
  end

  describe 'when a fallback is provided' do
    let(:es) { Locale.create!(name: 'Spanish') }

    before do
      HasLocalizationTable.config.current_locale = es
      a.save!
      HasLocalizationTable.config.current_locale = Locale.first
    end

    it "should return the fallback locale's string" do
      a.name(fallback: Locale.find(3)).must_equal 'Test'
    end

    it "should evaluate a proc" do
      a.name(fallback: -> * { Locale.find(3) }).must_equal 'Test'
    end

    it 'should return a given locale when specified' do
      a.name(Locale.find(3)).must_equal 'Test'
    end
  end
end