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

  describe 'when the required option is true' do
    before { Article.has_localization_table required: true }

    it "should add an error to the base class if a string is not given" do
      Article.has_localization_table required: true
      a = Article.new
      refute a.valid?
      a.errors.wont_be_empty
    end

    it 'should add an error to the association column if a string is not given' do
      Article.has_localization_table required: true
      a = Article.new(description: "Wishing the world hello!")
      s = a.localizations.first
      refute s.valid?
      s.errors[:name].wont_be_empty
    end
  end

  it "should not add validations if given required: false" do
    Article.has_localization_table required: false
    a = Article.new
    assert a.valid?
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