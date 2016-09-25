#!/usr/bin/ruby
# @Author: matt
# @Date:   2016-09-24 11:15:35
# @Last Modified by:   Matt
# @Last Modified time: 2016-09-25 01:31:23
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
        @departTime = Time.parse(json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureLocalTimeEstimatedActual"])

        # FLIGHT WAITLIST INFO
        tsaurl = "https://demo30-test.apigee.net/v1/hack/tsa?airport=" + departCode + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(tsaurl))
        json = JSON.parse(response)
        @delayTSA = json["WaitTimeResult"][0]["waitTime"].to_i
        @delayTravel = params[:mapdelay][:duration][:value].to_i / 60
        bufferTime = 30
        @departTime = @departTime.getlocal
        @currTime = (Time.new).getlocal
        @leaveAt = @departTime + bufferTime + @delayTravel + @delayTSA
        @leaveAt = @leaveAt.strftime("%I:%M %p")
        # .strftime("%I:%M %p")
        #setup and return result erb
        erb :result
    end
    # start if launching file
    run! if app_file == $0
end
