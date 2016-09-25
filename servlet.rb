#!/usr/bin/ruby
# @Author: matt
# @Date:   2016-09-24 11:15:35
# @Last Modified by:   Matt
# @Last Modified time: 2016-09-25 11:01:37
require 'sinatra/base'
require 'net/http'
require 'json'

class FlightServlet < Sinatra::Base

    get "/" do
        erb :index
    end

    post "/city" do
        # GET DEPARTURE INFO
        url = "https://demo30-test.apigee.net/v1/hack/status?flightNumber=" + params[:flightnum] + "&flightOriginDate=" + params[:flightdate] + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(url))
        json = JSON.parse(response)
        # get lat and long for location of departure
        departLat = json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureTsoagLatitudeDecimal"]
        departLong = json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureTsoagLongitudeDecimal"]
        # return info as JSON
        content_type :json
        {'lat' => departLat.to_f, 'long' => departLong.to_f}.to_json
    end

    post "/result" do
        # FLIGHT NUMBER INFO
        @num = params[:flightnum]
        flighturl = "https://demo30-test.apigee.net/v1/hack/status?flightNumber=" + @num + "&flightOriginDate=" + params[:flightdate] + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(flighturl))
        json = JSON.parse(response)
        departCode = json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureAirportCode"]
        @departTime = Time.parse(json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureLocalTimeScheduled"])

        # FLIGHT WAITLIST INFO
        tsaurl = "https://demo30-test.apigee.net/v1/hack/tsa?airport=" + departCode + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(tsaurl))
        json = JSON.parse(response)
        @delayTSA = json["WaitTimeResult"][0]["waitTime"].to_i
        @delayTravel = (params[:mapdelay][:duration][:value].to_i)
        bufferTime = 30.0
        @departTime = @departTime.getlocal
        @currTime = (Time.now).localtime
        @leaveAt = @departTime - (bufferTime * 60.0 + @delayTravel + @delayTSA)
        #formatting time
        @delayTravel = @delayTravel / 60
        @leaveAt = @leaveAt.strftime("%I:%M %p")
        @departTime = @departTime.strftime("%I:%M %p")
        @currTime = @currTime.strftime("%I:%M %p")
        # .strftime("%I:%M %p")
        #setup and return result erb
        erb :result
    end
    # start if launching file
    run! if app_file == $0
end
