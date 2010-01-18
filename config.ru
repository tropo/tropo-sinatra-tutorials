%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb).each{ |lib| require lib}

set :environment, :development
run Sinatra::Application
