# HasLocalizationTable

[![Gem Version](https://badge.fury.io/rb/has_localization_table.svg)](https://badge.fury.io/rb/has_localization_table)
[![Build Status](https://travis-ci.org/dvandersluis/has_localization_table.svg?branch=master)](https://travis-ci.org/dvandersluis/has_localization_table)

ActiveRecord plugin which adds setup and convenience methods for working with a relational localization table for user-driven data.

Adds accessors to retrieve localized attributes using the current locale, in order to avoid having to collect the correct object each time a value is needed. Localized attribute values are also cached for the current locale.

## Installation

Add this line to your application's Gemfile:

    gem 'has_localization_table'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_localization_table

## Usage

The gem assumes that the localization table has already been migrated, and the model for it contains `belongs_to` associations for the locale table and the base table. You only need to call the `has_localization_table` method on the base model.

	class Article < ActiveRecord::Base
	  # assuming ArticleLocalizations has name and body columns
	  has_localization_table :localizations, required: true, class_name: "ArticleLocalizations"
	end
	
	# Localized attributes can be retrieved by accessor...
	a = Article.new(name: "Once Upon a Time...", body: "There once lived a princess locked away in a tower!")
	a.name # "Once Upon a Time..."
	a.body # "There once lived a princess locked away in a tower!"
	
	# ... or set directly
	a.name = "Sleeping Beauty"
	
	# After changing to a different locale
	a.name = "Belle au Bois Dormant"
	a.body = "Il était une fois une princesse enfermée dans une tour!"
	
	a.localizations
	=> [<ArticleLocalization id: 1, article_id: 1, locale_id: 1, name: "Sleeping Beauty", body: "There once lived a princess locked away in a tower!">,
	    <ArticleLocalization id: 2, article_id: 1, locale_id: 2, name: "Belle au Bois Dormant", body: "Il était une fois une princesse enfermée dans une tour!">]
	    
	# Finder and order convenience methods are also provided:
	Article.find_by_name("Snow White")
	Article.find_by_body("...")
	Article.find_by_name_and_body("...", "...")
	Article.ordered_by_name # uses Arel, so it can be chained with other finder methods

### `has_localization_table` Arguments
If given, the first argument is the name used for the association, otherwise it defaults to `strings`.

* `class_name` (default: base class name + class_suffix) - the name of the localization class.
* `required` (default: false) - if true, at least a localization object for the primary language (see Configuration section) must be present or validation will fail
* `optional` (default: []) - if `required` is true, can be used to specify that specific attributes are optional

Any options that can be passed into `has_many` can also be passed along and will be used when creating the association.
	
## Configuration
`HasLocalizationTable` can also be configured as follows. Note that if any configuration option responds to `call`, it will be called.

	HasLocalizationTable.configure do |config|
	  # Default suffix to use for Localization class names
	  # ie. Article -> ArticleLocalization
	  config.class_suffix = "Localization"
	  
	  # Default localizations association name
      config.default_association_name = :localizations
      
      # Class name for Locale objects
	  config.locale_class = "Locale"
	  
	  # Foreign key used in localization tables to relate to a Locale
      config.locale_foreign_key = "locale_id"
      
      # Primary (main) locale
	  config.primary_locale = ->{ Locale.primary_language }
	  
	  # Current locale
	  config.current_locale = ->{ Locale.current_language }
	  
	  # All available locales
	  config.all_locales = ->{ Locale.all }
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
