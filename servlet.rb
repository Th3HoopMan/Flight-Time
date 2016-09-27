#!/usr/bin/ruby
# @Author: matt
# @Date:   2016-09-24 11:15:35
# @Last Modified by:   Matt
# @Last Modified time: 2016-09-27 16:53:32
require 'sinatra/base'
require 'net/http'
require 'json'

class FlightServlet < Sinatra::Base

    get "/" do
        @GoogleGeocoderApiKey = "AIzaSyDTBk3UaCJDysJBFEWM5RxOsPBfV55A6MI"
        erb :index
    end
    post "/city" do
        # GET DEPARTURE INFO
        url = "https://demo30-test.apigee.net/v1/hack/status?flightNumber=" + params[:flightnum] + "&flightOriginDate=" + params[:flightdate] + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(url))
        json = JSON.parse(response)
        departLat = json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureTsoagLatitudeDecimal"]
        departLong = json["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureTsoagLongitudeDecimal"]
        content_type :json
        {'lat' => departLat.to_f, 'long' => departLong.to_f}.to_json
    end
    post "/result" do
        # FLIGHT NUMBER API RESULTS
        @num = params[:flightnum]
        url1 = "https://demo30-test.apigee.net/v1/hack/status?flightNumber=" + @num + "&flightOriginDate=" + params[:flightdate] + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(url1))
        json_flight = JSON.parse(response)
        departCode = json_flight["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureAirportCode"]
        @departDate = Time.parse(json_flight["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureLocalTimeScheduled"])
        @departureAirportName = json_flight["flightStatusResponse"]["statusResponse"]["flightStatusTO"]["flightStatusLegTOList"]["departureAirportName"]
        # FLIGHT WAITLIST INFO
        url2 = "https://demo30-test.apigee.net/v1/hack/tsa?airport=" + departCode + "&apikey=FQFMhNJmXqB34vRNk4THrnT9RiRnLiUG"
        response = Net::HTTP.get(URI(url2))
        json_tsa = JSON.parse(response)
        @delayTSA = json_tsa["WaitTimeResult"][0]["waitTime"].to_i + 4
        # GOOGLE GEOCODE RESULTS
        @delayTraveltotalSeconds = (params[:mapdelay][:duration][:value].to_i)


        # DATE/TIME variables
        @currDate = Time.parse(params[:usertime])
        @departDate = @departDate.getlocal
        @leaveAt = @departDate - (30*60 + @delayTraveltotalSeconds + @delayTSA)
        delayTravelMins = @delayTraveltotalSeconds / 60
        delayTravelHours = delayTravelMins/60
        delayTravelHoursMins = delayTravelMins%60
        if (delayTravelHours >= 1)
            @delayTravel = delayTravelHours.to_s + " hour " + delayTravelHoursMins.to_s + " minutes"
        else
            @delayTravel = delayTravelMins.to_s + " minutes"
        end


        #formatting
        @leaveAtSameDay = @leaveAt.strftime("%I:%M %p %Z")
        @leaveAtTxt = @leaveAt.strftime("%A %I:%M %p %Z")
        @departTime = @departDate.strftime("%A %I:%M %p %Z")


        # PAGE RETURN
        code = :result
        if ((@departDate.to_f - @currDate.to_f) < 0)
            code = :result_old_date
        end
        erb code
    end
    # start if launching file
    run! if app_file == $0
end
