%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp open-uri json).each{|lib| require lib}
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
    on  :event => 'continue', :next => '/next.json'   # Where to next, captain?
    say "Welcome to the Tropo Weather Forecast hotline. We use Yahoo to fetch the weather for you."
    ask :name => 'zip', :bargein => true, :timeout => 7, :required => true, :attempts => 4,
        :say => [{:event => "timeout", :value => "Sorry, I did not hear anything."},
                 {:event => "nomatch:1 nomatch:2 nomatch:3", :value => "That wasn't a 5 digit number."},
                 {:value => "Please enter a 5 digit U.S. zip code."},
                 {:event => "nomatch:3", :value => "This is your last attempt. Watch it."}],
                  :choices => { :value => "[5 DIGITS]"}
      
    ask :name => 'day', :bargein => true, :timeout => 7, :required => true, :attempts => 4,
        :say => [{:event => "timeout", :value => "Sorry, I did not hear anything."},
                 {:event => "nomatch:1 nomatch:2 nomatch:3", :value => "That wasn't valid input.."},
                 {:value => "Do you want the weather for today or tomorrow? Press or say 0 for today, or 1 for tomorrow."},
                 {:event => "nomatch:3", :value => "This is your last attempt. Watch it."}],
                  :choices => { :value => "0, 1"}
  end
  t.response
end

post '/next.json' do  
v = Tropo::Generator.parse request.env["rack.input"].read
t = Tropo::Generator.new do
  pp v
  callwide_events()
  zip = v[:result][:actions][:zip][:interpretation]
  day = v[:result][:actions][:day][:interpretation]
  
  yahoo_url = "http://query.yahooapis.com/v1/public/yql?format=json&q="
  query = "SELECT * FROM weather.forecast WHERE location = " + zip
  url = URI.encode(yahoo_url + query)
  weather_data = JSON.parse(open(url).read)
  weather_results = weather_data["query"]["results"]["channel"]
  
  unless weather_results["title"] == "Yahoo! Weather - Error"
    say :value => weather_results["description"]
    case day
      when '0' # Today
        say "The forecast for today is #{weather_results["item"]["forecast"][day.to_i]["text"]}. " +
            "High of #{weather_results["item"]["forecast"][day.to_i]["high"]} degrees, " +
            "low of #{weather_results["item"]["forecast"][day.to_i]["low"]} degrees."
      when '1' # Tomorrow
        say "The forecast for tomorrow is #{weather_results["item"]["forecast"][day.to_i]["text"]}. " +
            "High of #{weather_results["item"]["forecast"][day.to_i]["high"]} degrees, " +
            "low of #{weather_results["item"]["forecast"][day.to_i]["low"]} degrees."
      else raise StandardError, "No day received ... #{day.inspect}"
    end
  else
    say "You didn't tell us a valid zip code so I can't really help you. Try again."
  end
  
  say "Thank you. This application powered by Tropo dot com."
  
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

post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  pp v # Print the JSON to our Sinatra console/log so we can find the error
  puts "!"*10 + "ERROR (see rack.input above), call ended"
end