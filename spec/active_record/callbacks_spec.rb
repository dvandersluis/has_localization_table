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

  it 'should initialize the localizations association on initialize' do
    a = Article.new
    a.localizations.wont_be_empty
  end

  it 'should initialize the localizations association on initialize for an existing object' do
    a = Article.find(article.id)
    a.localizations.wont_be_empty
  end

  it 'should not initialize the association on initialize if initialize: false is given in config' do
    Article.has_localization_table initialize: false
    a = Article.new
    a.localizations.must_be_empty
  end

  it 'should not initialize the association for an existing object if initialize: false is given in config' do
    Article.has_localization_table initialize: false
    a = Article.find(article.id)
    refute(a.localizations.loaded?)
  end

  it 'should not initialize the association on initialize if include: true is given in config' do
    Article.has_localization_table include: true
    a = Article.new
    a.localizations.must_be_empty
  end

  it 'should load associations if include: true is given' do
    Article.has_localization_table include: true
    assert Article.find(article.id).localizations.loaded?
  end
end
