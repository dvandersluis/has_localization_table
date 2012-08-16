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
  end
end