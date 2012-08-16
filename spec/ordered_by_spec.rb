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
  
  it "should create ordered_by methods" do
    a.save!
    b = Article.create!(name: "Name", description: "Another Description")
    c = Article.create!(name: "Once Upon a Time...", description: "Fairytale")
    Article.ordered_by_name.must_equal [b, c, a]
    Article.ordered_by_description.must_equal [b, a, c]
    Article.ordered_by_name(false).must_equal [a, c, b]
  end
  
  it "should allow ordered_by methods to apply to scope chains" do
    a.save!
    b = Article.create!(name: "Name", description: "Another Description")
    c = Article.create!(name: "Once Upon a Time...", description: "Fairytale")
    Article.scoped.ordered_by_name.must_equal [b, c, a]
  end
end