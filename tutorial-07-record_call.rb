%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
enable :sessions

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  session[:session_id] = v[:session][:session_id]
  session[:caller] = v[:session][:from]
  t = Tropo::Generator.new
    t.on :event => 'error', :next => '/error.json'     # For fatal programming errors. Log some details so we can fix it
    t.on :event => 'hangup', :next => '/hangup.json'   # When a user hangs or call is done. We will want to log some details.
    t.on :event => 'continue', :next => '/next.json'
    t.say "Hello #{session[:caller][:id]}"
    t.start_recording(:name => 'recording', :url => "http://heroku-voip.marksilver.net/post_audio_to_s3?filename=#{session[:call_id]}.wav&unique_id=#{session[:call_id]}")
    # [From this point, until stop_recording(), we will record what the caller *and* the IVR say]
    t.say "You are now on the record."
    # Prompt the user to incriminate themselve on-the-record
    t.say "Go ahead, sing-along."
    t.say "http://denalidomain.com/music/keepers/HappyHappyBirthdaytoYou-Disney.mp3"
  t.response
end

post '/next.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  t = Tropo::Generator.new
    t.on  :event => 'error', :next => '/error.json'     # For fatal programming errors. Log some details so we can fix it
    t.on  :event => 'hangup', :next => '/hangup.json'   # When a user hangs or call is done. We will want to log some details.
    t.say "What a great song..."
    t.say "You are a talented singer, #{session[:caller][:id]}"
  t.response
end

post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read

  #This is inside the hangup event document just in case they hangup before the call is officially "complete".
  #If it were at the end of the next event and the caller pre-maturely hung up, the audio would not be saved/transmitted to the server.  
  Tropo::Generator.stop_recording
  
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
