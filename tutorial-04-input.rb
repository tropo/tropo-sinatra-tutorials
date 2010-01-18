%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
enable :sessions

# This will save space later, since we want to direct the call to 
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
    on  :event => 'continue', :next => '/next.json'   # Where to next, captain?
    
    ask :name => 'favenum13', :bargein => true, :timeout => 5, :required => true, :attempts => 3,
    :say => [{:event => "timeout", :value => "Sorry, I didn't hear anything."},
              {:event => "nomatch:1 nomatch:2 nomatch:3", :value => "That wasn't a 2 to 3 digit number."},
              {:value => "Tell me your favorite 2 to 3 digit number."},
              {:event => "nomatch:3", :value => "This is your first attempt"}],
                :choices => { :value => "[2-3 DIGITS]"}
  end
  t.response
end

post '/next.json' do
v = Tropo::Generator.parse request.env["rack.input"].read
favenum13 = v[:result][:actions][:favenum13]
t = Tropo::Generator.new do
  callwide_events()
  if favenum13[:interpretation]
        say "#{favenum13[:interpretation]}?! Are you serious? That's my favorite number too."
        case favenum13[:attempts].to_i
          when 1      # Good job
          when 2..3   # Alright... not bad.
          when 4
            say "Shame on you! Do you have a problem listening to directions?"
          else puts "ELSE ERROR: #{favenum13.inspect}"
        end
  else
      say "Well, I guess you don't want us to know your favorite number. Goodbye."
  end
end
t.response  
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