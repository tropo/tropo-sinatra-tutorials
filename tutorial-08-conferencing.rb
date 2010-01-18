%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
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
    callwide_events()
    on  :event => 'continue', :next => '/nil/join.json'
    ask :name => 'confid', :bargein => true, :timeout => 7, :required => true, :attempts => 4,
        :say => [{:event => "timeout", :value => "Sorry, I did not hear anything."},
                 {:event => "nomatch:1 nomatch:2 nomatch:3", :value => "That wasn't a 1 digit number."},
                 {:value => "Please enter a one digit meeting room to join. If you're lost, try zero."},
                 {:event => "nomatch:3", :value => "This is your last attempt. Watch it."}],
                  :choices => { :value => "[1 DIGITS]"}
  end
  t.response
end

post '/:confid/join.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  if v[:result][:complete]; conference_id = v[:result][:actions][:confid][:interpretation]
  else conference_id = params[:confid].to_i.to_s #if nil, will default to 0.
  end
  t = Tropo::Generator.new do
    callwide_events()
    on  :event => 'continue', :next => '/after_conf.json'
    say "I'm transfering you into conference number #{conference_id}. Press the pound key to exit."
    conference({ :name       => conference_id, 
                 :id         => conference_id, 
                 :mute       => false,
                 :send_tones => false,
                 :exit_tone  => '#' })
  end
  t.response
end

post '/after_conf.json' do
  Tropo::Generator.say "You have left the conference. Thanks for using TropoML."
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