
# HasLocalizationTable

ActiveRecord plugin which adds setup and convenience methods for working with a relational localization table for user-driven data.

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
	  has_localization_table :localizations, required: true, class_name: "ArticleLocalizations"
	end

### `has_localization_table` Arguments
If given, the first argument is the name used for the association, otherwise it defaults to `strings`.

* `class_name` (default: base class name + "Strings"; ie. `ArticleStrings`) - the name of the localization class.
* `required` (default: false) - if true, at least a localization object for the primary language (see Configuration section) must be present or validation will fail
* `optional` (default: []) - if `required` is true, can be used to specify that specific attributes are optional

Any options that can be passed into `has_many` can also be passed along and will be used when creating the association.
	
## Configuration
`HasLocalizationTable` can also be configured as follows:

	HasLocalizationTable.configure do |config|
	  config.locale_class = "Locale"
	  config.locale_foreign_key = "locale_id"
	  config.primary_locale = Locale.primary_language
	  config.current_locale = Locale.current_language
	  config.all_locales = Locale.all
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
