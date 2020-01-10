source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree_core', github: 'spree/spree', branch: 'master'
gem 'spree_backend', github: 'spree/spree', branch: 'master'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: 'master'
gem 'rails-controller-testing'

gem 'rubocop', require: false
gem 'rubocop-rspec', require: false

gem 'money'
gem 'offsite_payments', path: '../offsite_payments'

group :development do
  gem 'httplog'
  gem 'pry'
end

group :test do
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 3.8.0'
  gem 'rspec-activemodel-mocks'
end

gemspec
