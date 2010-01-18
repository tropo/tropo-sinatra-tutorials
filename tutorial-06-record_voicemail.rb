### NEEDS WORK. CAN'T BE TESTED UNTIL ON STAGING SERVER
### NEEDS WORK. CAN'T BE TESTED UNTIL ON STAGING SERVER
### NEEDS WORK. CAN'T BE TESTED UNTIL ON STAGING SERVER
### NEEDS WORK. CAN'T BE TESTED UNTIL ON STAGING SERVER
### NEEDS WORK. CAN'T BE TESTED UNTIL ON STAGING SERVER

%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}

# This will save space later, since we want to direct the call to 
def callwide_events()
  on  :event => 'error', :next => '/error.json'     # For fatal programming errors. Log some details so we can fix it
  on  :event => 'hangup', :next => '/hangup.json'   # When a user hangs or call is done. We will want to log some details.
end

post '/start.json' do
  t = Tropo::Generator.new do

  record({ :name       => 'voicemail',
           :url        => 'http://heroku-voip.marksilver.net/post_audio_to_s3&unique_id=101',
           :beep       => true,
           :send_tones => false,
           :exit_tone  => '#' }) do
              say     :value => 'Please leave your message after the tone.'
            end
  end
  t.response
end

post '/next.json' do  
v = Tropo::Generator.parse request.env["rack.input"].read
pp v
t = Tropo::Generator.new do
  callwide_events()
  say :value => 'Thank you for leaving your message. Ciao.'

  end
t.response  
end

post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  puts "Caller hung up before we finished! They only stayed on the line for #{v[:result][:session_duration]} second(s)"
end

post '/error.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  pp v # Print the JSON to our Sinatra console/log so we can find the error
  puts "!"*10 + "ERROR (see rack.input above), call ended"
end