%w(rubygems sinatra tropo-webapi-ruby/lib/tropo-webapi-ruby.rb pp).each{|lib| require lib}
enable :sessions

post '/start.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  session[:session_id] = v[:session][:session_id]
  session[:caller] = v[:session][:from] # [:id] = Numeric, [:name] = Name (both default to "unknown")
  t = Tropo::Generator.new # Here's another way to build your Tropo JSON request, without using a block.
  t.on  :event => 'hangup', :next => '/hangup.json'
  t.on  :event => 'next', :next => '/next.json'
  t.say :value => "Hello #{session[:caller][:id]}"
  t.say :value => " la la la la la hey!"*10
  t.response
  
end

post '/hangup.json' do
  # Hang up event when a) caller hangs up, b) script finishes executing. Defined by on :event above.
  v = Tropo::Generator.parse request.env["rack.input"].read
  # (Thanks to our session storage with Sinatra, we can recall the session[:id] and caller info down here.)
  puts "/!\\ Call hung up. They only listened for #{v[:result][:session_duration]} second(s)"
  puts "    Caller info: ID=#{session[:caller][:id]}, Name=#{session[:caller][:name]}"
  puts "    Call logged in CDR. Tropo session ID: #{session[:session_id]}"
end