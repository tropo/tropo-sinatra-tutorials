%w(rubygems sinatra tropo-ruby/lib/tropo.rb pp).each{|lib| require lib}
set :environment, :development
run Sinatra::Application
