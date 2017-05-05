require 'json'
require "sinatra"
require 'shotgun'
require 'active_support/all'
require "active_support/core_ext"
require 'rake'

require 'particle'  # require particle gem to talk to the photon
require 'twilio-ruby'  # connect to twilio

# require 'sinatra/activerecord'
# require 'pg'



# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
configure :development do
  require 'dotenv'
  Dotenv.load
end


# CREATE A CLient
client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
particle_client = Particle::Client.new( access_token: ENV['PARTICLE_ACCESS_TOKEN'] )


# # Fetch the list of devices using a newly created client
# particle_client = Particle::Client.new
# # Fetch the list of devices
# particle_client.devices

# device = Particle.device('betch')


# Use this method to check if your ENV file is set up
get "/" do
  "Hello world!"
end

get "/from" do
  ENV["TWILIO_FROM"]
end

# Test sending an SMS
# change the to to your number 
get "/send_sms" do

  client.account.messages.create(
    :from => "+14152002424",
    :to => "+12067130783",
    :body => "Hey there. This is a test"
  )

  "Sent message"
  
end


# Hook this up to your Webhook for SMS/MMS through the console
get '/incoming_sms' do

  session["counter"] ||= 0
  count = session["counter"]
  
  sender = params[:From] || ""
  body = params[:Body] || ""
  body = body.downcase.strip
  
  event_data = ""

  if not defined? session["last_context"] or session["last_context"] == nil
    session["last_context"] = "num_days"
    event_data = "foodtype:#{ body }"
    message = "Please enter a number to set the number of days of the timer"
  elsif session["last_context"] == "num_days"
    session["last_context"] = nil
    event_data = "numdays:#{ body }"
    message = "Your timer is set for #{body} days. Great!"
    
  end

  particle_client.publish(name: "smart_food/sms/incoming/#{sender}", data: event_data)

  
  session["counter"] += 1
  
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message message
  end

  content_type 'text/xml'

  twiml.text

end

error 401 do 
  "Not allowed!!!"
end

