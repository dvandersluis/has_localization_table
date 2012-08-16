require 'spec_helper'

describe HasLocalizationTable do
  before do
    # Configure HLT
    HasLocalizationTable.configure do |c|
      c.primary_locale = Locale.first 
      c.current_locale = Locale.first
      c.all_locales = Locale.all
    end
  end
  
  describe "#has_localization_table" do
    before do
      Object.send(:remove_const, :Article) rescue nil
      Article = Class.new(ActiveRecord::Base)
    end
    
    it "should track any given options" do
      Article.has_localization_table :strings, required: true, optional: [:description]
      Article.localization_table_options.slice(:association_name, :required, :optional).must_equal({ association_name: :strings, required: true, optional: [:description] })
    end
    
    it "should define has_many association on the base class with a default name of :localizations" do
      Article.has_localization_table
      assoc = Article.reflect_on_association(:localizations)
      assoc.wont_be_nil
      assoc.macro.must_equal :has_many
      assoc.klass.must_equal ArticleLocalization
    end
    
    it "should use the given association name" do
      Article.has_localization_table :strings
      assoc = Article.reflect_on_association(:strings)
      assoc.wont_be_nil
      assoc.macro.must_equal :has_many
      assoc.klass.must_equal ArticleLocalization
    end
    
    it "should use the given class" do
      ArticleText = Class.new(ArticleLocalization)
      Article.has_localization_table class_name: ArticleText
      assoc = Article.reflect_on_association(:localizations)
      assoc.wont_be_nil
      assoc.macro.must_equal :has_many
      assoc.klass.must_equal ArticleText
      
      Object.send(:remove_const, :ArticleText)
    end
     
    it "should add validations if given required: true" do
      Article.has_localization_table required: true
      a = Article.new
      refute a.valid?
      a.errors[:localizations].wont_be_empty
      
      a = Article.new(description: "Wishing the world hello!")
      s = a.localizations.first
      refute s.valid?
      s.errors[:name].wont_be_empty
    end
    
    it "should not add validations if given required: false" do
      Article.has_localization_table required: false
      a = Article.new
      a.valid? or raise a.localizations.map(&:errors).inspect
      a.errors[:localizations].must_be_empty
      
      a = Article.new(description: "Wishing the world hello!")
      s = a.localizations.first
      assert s.valid?
      s.errors[:name].must_be_empty
    end
    
    it "should not add validations if required is not given" do
      Article.has_localization_table
      a = Article.new
      assert a.valid?
      a.errors[:localizations].must_be_empty
      
      a = Article.new(description: "Wishing the world hello!")
      s = a.localizations.first
      assert s.valid?
      s.errors[:name].must_be_empty
    end
    
    it "should not add validations for optional fields" do
      Article.has_localization_table required: true, optional: [:description]
      a = Article.new(name: "Test")
      assert a.valid?
      a.errors[:localizations].must_be_empty
      assert a.localizations.all?{ |s| s.errors[:description].empty? }
    end
  end
end