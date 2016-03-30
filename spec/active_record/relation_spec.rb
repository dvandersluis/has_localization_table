require 'spec_helper'
#require 'active_record/relation'

describe HasLocalizationTable do
  before do
    # Configure HLT
    HasLocalizationTable.configure do |c|
      c.primary_locale = Locale.first
      c.current_locale = Locale.first
      c.all_locales = Locale.all
    end

    Object.send(:remove_const, :Article) rescue nil
    Article = Class.new(ActiveRecord::Base) do
      def self.localization_association_name; :strings; end
      def self.localization_table_options; {}; end
      def self.localization_class; ArticleLocalization; end
      def self.localized_attributes; []; end
    end
  end

  subject do
    Article.send(:extend, HasLocalizationTable::ActiveRecord::Relation)
    Article
  end

  it "should alias with_localizations with the actual association name" do
    assert subject.respond_to? :with_strings
  end

  it "should create a has_many association" do
    reflection = subject.reflect_on_association(:strings)
    refute_nil reflection
    reflection.macro.must_equal :has_many
  end

  it "should create a has_one association" do
    reflection = subject.reflect_on_association(:string)
    refute_nil reflection
    reflection.macro.must_equal :has_one
  end

  it "should alias the has_one association as localization" do
    reflection = subject.reflect_on_association(:localization)
    refute_nil reflection
    reflection.macro.must_equal :has_one
  end

  it "should not create a has_one association if disabled in configuration" do
    HasLocalizationTable.stub :create_has_one_by_default, false do
      assert_nil subject.reflect_on_association(:localization)
    end
  end

  it "should not create a has_one association if disabled in table options" do
    Article.stub :localization_table_options, { has_one: false } do
      assert_nil subject.reflect_on_association(:localization)
    end
  end

  it "should create a has_one association if asked for, even if disabled in configuration" do
    HasLocalizationTable.stub :create_has_one_by_default, false do
      Article.stub :localization_table_options, { has_one: true } do
        reflection = subject.reflect_on_association(:localization)
        refute_nil reflection
        reflection.macro.must_equal :has_one
      end
    end
  end

  it "should not create an association that conflicts with an attribute name" do
    Article.stub :localized_attributes, [:string] do
      Article.send(:extend, HasLocalizationTable::ActiveRecord::Relation)
      assert_nil Article.reflect_on_association(:string)
    end
  end

  it "should use the current locale for the has_one association" do
    locale = MiniTest::Mock.new
    locale.expect :id, 2

    conditions = subject.reflect_on_association(:string).options[:conditions]

    HasLocalizationTable.stub :current_locale, locale do
      conditions.call.must_equal "article_localizations.locale_id = 2"
    end

    locale.expect :id, 3

    HasLocalizationTable.stub :current_locale, locale do
      conditions.call.must_equal "article_localizations.locale_id = 3"
    end
  end

  it 'should add a default scope if include: true is given' do
    Article.stub :localization_table_options, { include: true } do
      Article.default_scopes.must_be_empty
      Article.send(:extend, HasLocalizationTable::ActiveRecord::Relation)
      Article.default_scopes.size.must_equal(1)
    end
  end

  it 'should not add a default scope if include: false is given' do
    Article.stub :localization_table_options, { include: false } do
      Article.send(:extend, HasLocalizationTable::ActiveRecord::Relation)
      Article.default_scopes.must_be_empty
    end
  end

  it 'should not add a default scope if include: is not given' do
    Article.stub :localization_table_options, { } do
      Article.send(:extend, HasLocalizationTable::ActiveRecord::Relation)
      Article.default_scopes.must_be_empty
    end
  end
end
