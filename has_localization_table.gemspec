# -*- encoding: utf-8 -*-
require File.expand_path('../lib/has_localization_table/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Daniel Vandersluis"]
  gem.email         = ["dvandersluis@selfmgmt.com"]
  gem.description   = %q{Automatically sets up usage of a relational table to contain user-created multi-locale string attributes}
  gem.summary       = %q{Sets up associations and attribute methods for AR models that have a relational table to contain user-created data in multiple languages.}
  gem.homepage      = "https://github.com/dvandersluis/has_localization_table"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "has_localization_table"
  gem.require_paths = ["lib"]
  gem.version       = HasLocalizationTable::VERSION
  
  gem.add_dependency 'activesupport', ['>= 3.0.0']
  gem.add_dependency 'activerecord', ['>= 3.0.0']
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'rake'
end

