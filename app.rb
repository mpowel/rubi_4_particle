# deployed to https://salty-dawn-69757.herokuapp.com/
# manage on heroku at : https://dashboard.heroku.com/apps/salty-dawn-69757/settings

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


  # if get_context == "num_days"
  #     session["last_context"] = nil
  #     event_data = "numdays:#{ body }"
  #     message = "Great! Your timer is now set for #{body} days. "
  # elsif not defined? session["last_context"] or get_context == nil
  #   session["last_context"] = "num_days"
  #   event_data = "foodtype:#{ body }"
  #   message = "Enter a number to set my timer. # of days consider it spoiled?"
  # end
  
  if body.starts_with? "set"
    # session["last_context"] = "set_by_user"
    event_data = "settime:#{ body }"
    message = "Enter a value 1-30 to set the number of days for the timer."
  elsif body == 1 or body == 2 or body == 3
    # numdays_short = body.gsub( "delete contact", "" ).strip
    # session["last_context"] = nil
    event_data = "numdays_short:#{ body }"
    message = "Timer set for #{ body } days. You can now place me in the fridge. Fun fact, savethefood.com says aside from raw meats most food can be stored more than 3 days. To reset timer, type any number >3."
  # elsif get_context == "set_by_user" and event_data. >= 4
#     session["last_context"] = nil
#     event_data = "numdays_OK:#{ body }"
#     message = "Great! Your timer is set for #{body} days. Go ahead and place me in the fridge."
    #
  # else
  #   session["last_context"] = "error_message"
  #   event_data = "error:#{ body }"
  #   message = "Sorry, I didn't get that."
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
  "Sorry, I didn't get that."
end

def get_context
  session["last_context"] || nil
end 

