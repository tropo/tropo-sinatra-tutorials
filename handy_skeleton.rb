%w(rubygems sinatra tropo-ruby/lib/tropo-ruby.rb pp).each{|lib| require lib}
enable :sessions

def callwide_events()
  on  :event => 'error', :next => '/error.json'     # For fatal programming errors. Log some details so we can fix it
  on  :event => 'hangup', :next => '/hangup.json'   # When a user hangs or call is done. We will want to log some details.
end

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  session[:session_id] = v[:session][:session_id]
  session[:caller] = v[:session][:from]

  t = Tropo::Generator.new do
    # TROPO ROCKS!
  end
  
  t.response # Execute generated Tropo actions
  
end

post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  if v[:result][:complete]
    puts "Call complete. Call duration: #{v[:result][:session_duration]} second(s)"
  else
    puts "/!\\ Caller hung up. Call duration: #{v[:result][:session_duration]} second(s)."
  end
  puts "    Caller info: ID=#{session[:caller][:id]}, Name=#{session[:caller][:name]}"
  puts "    Call logged in CDR. Tropo session ID: #{session[:session_id]}"
end

post '/error.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  pp v # Print the JSON to our Sinatra console/log so we can find the error
  puts "!"*10 + "ERROR (see rack.input above), call ended"
end