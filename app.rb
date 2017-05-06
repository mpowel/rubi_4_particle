require 'json'
require "sinatra"
require 'shotgun'
require 'active_support/all'
require "active_support/core_ext"
require 'rake'
require 'particle'  # require particle gem to talk to the photon
require 'twilio-ruby'  # connect to twilio


# enable sessions for this project
enable :sessions


# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
configure :development do
  require 'dotenv'
  Dotenv.load
end


# CREATE A CLient
client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
particle_client = Particle::Client.new( access_token: ENV['PARTICLE_ACCESS_TOKEN'] )


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

  print session["counter"]
  print session["last_context"]

  if get_context != nil and event_data < 4 and > 1
      session["last_context"] = "timer_too_short"
      event_data = "shorttimer:#{ body }"
      message = "Are you sure? savethefood.com recommends 7-10 days for fruit, veggies, & opened dairy and 2-3 for raw meat or fish. Reply YES to confirm or NO to reset."
  elsif get_context == "num_days"
      session["last_context"] = nil
      event_data = "numdays:#{ body }"
      message = "Great! Your timer is now set for #{body} days. "
  elsif not defined? session["last_context"] or get_context == nil
    session["last_context"] = "num_days"
    event_data = "foodtype:#{ body }"
    message = "Enter a number to set my timer. # of days consider it spoiled?"
  end
  
  # if get_context == "num_days"
#       session["last_context"] = nil
#       event_data = "numdays:#{ body }"
#       message = "Great! Your timer is now set for #{body} days. "
#       message = "I'll monitor your food with my digital sniffer and 12 hours before #{body} days are up, I'll remind you "
#   elsif not defined? session["last_context"] or get_context == nil
#     session["last_context"] = "num_days"
#     event_data = "foodtype:#{ body }"
#     message = "Did you know? Food waste costs the average American family up to $2,000/year, but not you! You made the smart choice with smartware. ;) "
#   end

  particle_client.publish(name: "smart_food/sms/incoming/#{sender}", data: event_data)

  session["counter"] += 1
  
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message message
  end

  content_type 'text/xml'

  twiml.text

end

error 401 do 
  "Sorry, I didn't get that."
end

def get_context
  
  session["last_context"] || nil
end 

