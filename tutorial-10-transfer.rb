%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
enable :sessions

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  session[:session_id] = v[:session][:session_id]
  session[:caller] = v[:session][:from]

  t = Tropo::Generator.new
    t.on  :event => 'error', :next => '/error.json'   
    t.on  :event => 'continue', :next => '/next.json'   
    
    t.say "I'm transferring you to another app..."
    t.transfer :to => 'sip:9991429430@sip.tropo.com'
  t.response
end

post '/next.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  if v[:result][:actions][:disposition] == "SUCCESS"
    puts "Transfered call has completed."
    puts "  They were on the phone with them for #{v[:result][:actions][:duration]} second(s)"
    puts "  They used our service for a total of #{v[:result][:session_duration]} second(s)"
  else
    t = Tropo::Generator.new
      t.say "Sorry, but something went wrong and I was unable to transfer you."
    t.response
  end
  
end

post '/error.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  pp v # Print the JSON to our Sinatra console/log so we can find the error
  puts "!"*10 + "ERROR (see rack.input above), call ended"
end