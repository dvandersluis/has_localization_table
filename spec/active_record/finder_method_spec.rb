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
  
  it "should create finder methods" do
    a.save!
    Article.find_by_name("Test").must_equal a
    Article.find_by_description("Description").must_equal a
    Article.find_by_name_and_description("Test", "Description").must_equal a
    Article.find_by_description_and_name("Description", "Test").must_equal a
    
    Article.find_by_name("Wrong").must_be_nil
    Article.find_by_description("Wrong").must_be_nil
  end
end