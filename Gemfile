source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.1.0'
gem 'builder', '~> 3.0'   
gem 'i18n' # Need this explicitly, otherwise can't deploy

gem 'mysql2', '~> 0.3.7'  
#tmp# gem 'memcache-client' #gem 'dalli' #gem 'redis-store'

#tmp# dependency for linecache
gem 'require_relative'

gem 'json', '~> 1.6'
gem 'haml'#, '~> 3.1.2'
gem 'sass', '~> 3.1.7'
gem 'coffee-script', '~> 2.2.0'
gem 'uglifier', '~> 1.0.3'

gem 'jquery-rails', '~> 1.0'
gem 'rails_autolink', '~> 1.0.2'

gem 'will_paginate', '~> 3.0' 

gem 'thinking-sphinx', '~> 2.0.7', :require => 'thinking_sphinx'
#temp#sphinx# gem 'ts-delayed-delta', '1.1.0', :require => 'thinking_sphinx/deltas/delayed_delta'

gem 'zip', '~> 2.0.2'
gem 'rgl', '~> 0.4.0', :require => 'rgl/adjacency'

gem 'nested_set', '~> 1.6.8'
gem 'acts-as-dag', '~> 2.5.5' # TOOD use instead ?? gem 'dagnabit', '2.2.6'

<<<<<<< HEAD
# gem 'rmagick', '2.13.1', :require => 'RMagick2'
gem 'json', '~> 1.5.4'

=======
>>>>>>> next
gem 'net-ldap', :require => 'net/ldap'

gem 'zencoder'
gem 'uuidtools'
gem 'mini_exiftool'

# wiki:
# unfortunately upstream irwi is broken. Until it is fixed we
# install it as a plugin from our own branch on github:
# git@github.com:tpo/irwi.git
#gem 'irwi', :git => 'git://github.com/tpo/irwi.git'
gem 'irwi', :git => 'git://github.com/valodzka/irwi.git'
gem 'RedCloth'

group :test, :development do
  gem 'ruby-debug19', :require => 'ruby-debug' # for Ruby 1.8.x: gem 'ruby-debug'
  gem 'ruby-debug-completion'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-ext'
  #tmp# gem 'peterhoeg-railroad'
  #tmp# gem 'newrelic_rpm', '~> 3.1'
end

group :test do
<<<<<<< HEAD
  gem 'cucumber', '~> 1.0.2'
  gem 'cucumber-rails', '~> 1.0.2'
  gem 'capybara', '~> 1.0.1'
  gem 'selenium-webdriver', '~> 2.5.0' 
=======
  gem 'cucumber'#, '~> 1.0.3'
  gem 'cucumber-rails'#, '~> 1.0.2'
  gem 'capybara', '~> 1.1.1'
  gem 'selenium-webdriver', '~> 2.6' 
>>>>>>> next
  gem 'database_cleaner'
  gem 'rspec-rails'
  gem 'spork'
  gem 'launchy'  
  gem 'simplecov' # for Ruby 1.8.x:  gem 'rcov'
end
