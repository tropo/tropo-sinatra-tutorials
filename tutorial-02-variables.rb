%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  t = Tropo::Generator.new do
    say :value => "Hello!"
    caller_id = v[:session][:from][:id]
    if caller_id == "unknown"
      say :value => "We could not detect your caller ID."
    else
      say :value => "I see you called from #{caller_id}."
    end
    
    say :value => "Thank you for calling."
  end
  
  t.response
end