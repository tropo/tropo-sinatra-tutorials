%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
enable :sessions

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  session[:session_id] = v[:session][:session_id]
  session[:caller] = v[:session][:from]

  t = Tropo::Generator.new
    t.on  :event => 'error', :next => '/error.json'   
        
    unless session[:caller][:id] == "unknown"
      t.redirect :to => 'sip:9991429430@sip.tropo.com'
    else
      t.say "Sorry, but I cannot re-direct you without knowing who you are."
      t.say "Please call back with caller I.D. enabled."
      t.hangup
    end  
  t.response
end

post '/error.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  pp v # Print the JSON to our Sinatra console/log so we can find the error
  puts "!"*10 + "ERROR (see rack.input above), call ended"
end