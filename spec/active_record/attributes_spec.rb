require 'spec_helper'

describe HasLocalizationTable do
  before do
    # Configure HLT
    HasLocalizationTable.configure do |c|
      c.primary_locale = Locale.first
      c.current_locale = Locale.first
      c.all_locales = -> { Locale.all }
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
    a.reset_localized_attribute_cache

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

    it "should return the fallback locale's string when there isn't a string for the current locale" do
      a.name(fallback: es).must_equal 'Test'
    end

    it "should return the fallback locale's string when the string for the current locale is blank" do
      a.update_attributes!(name: '', description: 'Description')
      a.name(fallback: es).must_equal 'Test'
    end

    it 'should return a blank string if neither locale has a string' do
      HasLocalizationTable.with_options(current_locale: es) { a.update_attributes!(name: '') }
      a.name(fallback: es).must_be_empty
    end

    it "should evaluate a proc" do
      a.name(fallback: -> * { es }).must_equal 'Test'
    end

    it 'should return a given locale when specified' do
      a.name(es).must_equal 'Test'
    end

    it 'should not evaluate a proc if the fallback is not required' do
      HasLocalizationTable.config.current_locale = es
      a.name(fallback: -> * { raise ArgumentError }).must_equal 'Test'
    end

    it 'should use the fallback specified in configuration' do
      HasLocalizationTable.with_options(fallback_locale: -> * { es }) do
        a.name.must_equal 'Test'
      end
    end
  end

  describe 'when a fallback is not provided' do
    describe 'when the primary locale is the current locale' do
      it 'should return a blank string when the localization is nil' do
        a = Article.new(name: nil)
        a.name.must_be_empty
      end

      it 'should return a blank string if there is no localization' do
        a = Article.create!
        a.name.must_be_empty
      end

      it 'should return a blank string if the localization is blank' do
        a.update_attributes!(name: '')
        a.name.must_be_empty
      end
    end

    describe 'when the primary locale is different than the current locale' do
      let(:es) { Locale.create!(name: 'Spanish') }

      before do
        HasLocalizationTable.config.primary_locale = HasLocalizationTable.config.current_locale = es

        a.save!

        HasLocalizationTable.config.current_locale = Locale.first
        a.update_attributes!(name: '', description: 'Description')
      end

      it 'should return the primary locale string if the current locale string is blank' do
        a.name.must_equal 'Test'
      end

      it 'should return a blank string if neither locale has a string' do
        HasLocalizationTable.with_options(current_locale: HasLocalizationTable.primary_locale) { a.update_attributes!(name: '') }
        a.name.must_be_empty
      end
    end
  end

  it 'should build missing localizations when accessing the association' do
    HasLocalizationTable.config.all_locales = [Locale.first]

    a = Article.new
    a.localizations.size.must_equal 1
  end

  it 'should build missing localizations when there is more than 1 locale' do
    a = Article.new
    a.localizations.size.must_equal 2
  end

  it 'should not build localizations when they already exist' do
    a = Article.new
    l1 = ArticleLocalization.new(locale_id: Locale.first.id, name: 'Name')
    l2 = ArticleLocalization.new(locale_id: Locale.last.id, name: 'Nom')
    a.localizations = [l1, l2]
    a.localizations.must_equal [l1, l2]
    a.localizations.first.name.must_equal 'Name'
  end

  it 'should add missing localizations if some exist' do
    a = Article.new
    a.localizations = [ArticleLocalization.new(locale_id: Locale.first.id, name: 'Name')]
    a.association(:localizations).reader.size.must_equal 1
    a.localizations.size.must_equal 2
    a.localizations.first.name.must_equal 'Name'
  end

  it 'should not build missing localizations if asked not to' do
    a = Article.new
    a.localizations(false).must_be_empty
  end

  it 'should not build missing localizations if the options disable it' do
    Article.has_localization_table build_missing: false
    a = Article.new
    a.localizations.must_be_empty
  end

  it 'should build missing localizations if the options disable it but the method requests it' do
    Article.has_localization_table build_missing: false
    a = Article.new
    a.localizations(true).wont_be_empty
  end

  it 'should update the main model when the string is directly updated' do
    Article.has_localization_table
    a = Article.new

    string = a.localizations.first
    string.name = 'New Name'
    a.name.must_equal 'New Name'
  end

  it 'should allow successive changes' do
    Article.has_localization_table
    a = Article.new

    string = a.localizations.first
    string.name = 'New Name'
    a.name.must_equal 'New Name'

    string.name = 'Another Name'
    a.name.must_equal 'Another Name'
  end
end
