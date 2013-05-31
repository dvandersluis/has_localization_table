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

  it "should use the current locale for the has_one association" do
    locale = MiniTest::Mock.new
    locale.expect :id, 2

    conditions = subject.reflect_on_association(:string).options[:conditions]

    HasLocalizationTable.stub :current_locale, locale do
      conditions.call.must_equal "locale_id = 2"
    end

    locale.expect :id, 3

    HasLocalizationTable.stub :current_locale, locale do
      conditions.call.must_equal "locale_id = 3"
    end
  end
end