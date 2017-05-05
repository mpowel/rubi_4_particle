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

  if session["counter"] < 1
    message = "Food Waster: Thanks for your first message. From #{sender} saying #{body}"
    
  else
    message = "Food Waster: message number #{ count }. From #{sender} saying #{body}"
    
    
  end

  particle_client.publish(name: "smart_food/sms/incoming/#{sender}", data: "message received", ttl: 3600, private: true)

  
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

