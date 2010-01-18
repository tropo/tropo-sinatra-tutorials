%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}

post '/one.json' do
  Tropo::Generator.say 'Hello World!'
end

post '/two.json' do
  Tropo::Generator.new
  t.say 'Hello World!'
  t.response
end

post '/three.json' do
  Tropo::Generator.new do
    say 'Hello World!'
  end
  t.response
end