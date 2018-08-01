source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.13', '< 0.5'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'rack-cors', :require => 'rack/cors'
gem 'tzinfo-data'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  
  gem 'delayed_job'
  gem 'delayed_job_active_record', '~> 4.1.1' 
  #gem 'rmagick'
  
  # gem 'thin'
  gem 'prawn'
  gem 'prawn-table'
  gem 'axlsx', '2.1.0.pre'
  gem 'daemons'
  gem "bunny"
  
  gem 'recursive-open-struct', '~> 1.0', '>= 1.0.1'
  gem 'redis', '~> 4.0', '>= 4.0.1'
  
  # gem 'therubyracer'
  gem 'composite_primary_keys'
  # 很好用, by_day(Time.now) => where(created_at: [Time.now.beginning_of_day..Time.now.end_of_day])
  gem 'by_star'
  # 分页
  gem 'will_paginate'
  # rails5中实现的or的使用, post = Post.where('id = 1').or(Post.where('id = 2'))
  gem 'where-or'
  # 用于对表做log
  gem 'paper_trail', '8.1.2'
  gem 'simple_xlsx_reader'#, '1.0.2'
  gem 'clockwork'
  gem 'god'
  gem 'inifile', '~> 3.0'
  
  gem "roo", '2.7.1'
  gem 'roo-xls'

  # gem "mongo"
  # gem 'mongoid', '~> 5.2', '>= 5.2.1'
  gem 'msgpack', '~> 1.2', '>= 1.2.2'

  gem 'thin', '~> 1.7', '>= 1.7.2'
end

