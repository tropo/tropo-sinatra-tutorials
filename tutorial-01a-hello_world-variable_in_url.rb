%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}

# Just call say/hello/to/mark/from/jason.json@localhost:5555
#   or.. say/the_secret_code_is_8_7_6_7_6._Have_a_great_weekend!/to/mark/from/jason.json@localhost:5555
post '/say/:message/to/:name/from/:from.json' do
  Tropo::Generator.say "Hi #{params[:name]}," + 
          "#{params[:from]} has the following message for you: #{params[:message]}"
end
