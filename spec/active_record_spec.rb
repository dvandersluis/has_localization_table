require 'spec_helper'

# Setup in-memory database so AR can work
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Migration.tap do |m|
  m.create_table :articles do |t|
    t.timestamps
  end

  m.create_table :locales do |t|
    t.string :name
  end

  m.create_table :article_localizations do |t|
    t.integer :article_id
    t.integer :locale_id
    t.string :name
    t.string :description
  end
end

# Set up locales
Locale = Class.new(ActiveRecord::Base)
Locale.create!(name: "English")
Locale.create!(name: "French")

ArticleLocalization = Class.new(ActiveRecord::Base) do
  belongs_to :article
  belongs_to :locale
end

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
  
  describe "other methods" do
    before do
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
    
    it "should create finder methods" do
      a.save!
      Article.find_by_name("Test").must_equal a
      Article.find_by_description("Description").must_equal a
      Article.find_by_name_and_description("Test", "Description").must_equal a
      Article.find_by_description_and_name("Description", "Test").must_equal a
      
      Article.find_by_name("Wrong").must_be_nil
      Article.find_by_description("Wrong").must_be_nil
    end
    
    it "should create ordered_by methods" do
      a.save!
      b = Article.create!(name: "Name", description: "Another Description")
      c = Article.create!(name: "Once Upon a Time...", description: "Fairytale")
      Article.ordered_by_name.must_equal [b, c, a]
      Article.ordered_by_description.must_equal [b, a, c]
    end
  end
end