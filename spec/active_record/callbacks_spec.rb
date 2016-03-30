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

  let(:article) { Article.create!(name: "Test", description: "Description") }

  it 'should load associations if include: true is given' do
    Article.has_localization_table include: true
    assert Article.find(article.id).localizations.loaded?
  end
end
