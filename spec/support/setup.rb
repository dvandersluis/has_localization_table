# Setup in-memory database so AR can work
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Migration.tap do |m|
  m.create_table :articles do |t|
    t.timestamps null: false
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
