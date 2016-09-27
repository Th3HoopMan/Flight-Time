$(document).ready(function(){

    // var destinationA = '6000 N Terminal Pkwy, Atlanta, GA 30320';
    var userlocation;
    var flightnum;
    var flightdate;
    var duration;
    var pos;
    //local time for user
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth() + 1;
    var yyyy = today.getFullYear();
    if (dd < 10) dd = '0' + dd;
    if (mm < 10) mm = '0' + mm;
    document.getElementById("flightdate").defaultValue = (yyyy + '-' + mm + '-' + dd);
    //disable GPS button if not SSL certificate
    if (location.protocal !== 'https:') {
        $("#gpsText").html('GPS Requires HTTPS')
        document.getElementById("gpsBtn").disabled = true;
    }
    //get location
    $("#gpsBtn").click(function(){
        navigator.geolocation.getCurrentPosition(function(position) {
             pos = {
              lat: position.coords.latitude,
              lng: position.coords.longitude
            };
            userlocation = pos;
            console.log(pos);

            var geocoder = new google.maps.Geocoder;
            console.log(pos);
            var myLocal = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
            geocoder.geocode({'location': myLocal}, function(results, status) {
              if (status === 'OK') {
                var address = results[0];
                console.log(address.formatted_address);
                $("#loc-end-id").val(address.formatted_address);
              } else {
                console("We were not able to parse this into a real address");
              }
            });
        });

    });

    $("#submit").click(function(){
        flightdate = document.getElementById("flightdate").value;
        flightnum = document.getElementById("flightnum").value;
        userlocation = $("#loc-end-id").val()
        var service = new google.maps.DistanceMatrixService;

        if (flightnum == "") {
            $("#container-warning").html('<div class="alert alert-warning alert-dismissible fade in" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><strong>Error:</strong> please enter a flight number.</div>')
            return;
        } else if (flightdate == "") {
            $("#container-warning").html('<div class="alert alert-warning alert-dismissible fade in" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><strong>Error:</strong> please enter a date.</div>')
            return;
        } else if (userlocation == null || userlocation == "") {
            $("#container-warning").html('<div class="alert alert-warning alert-dismissible fade in" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><strong>Error:</strong> please enter a location.</div>')
            return;
        }
        $('#result-panel').html("")
        document.getElementById("spinner-div").style.visibility = "visible";
        // AJAX CALL TO GET LATLNG FOR GOOGLE MAPS CALCULATION
        $.ajax({
            type: 'post',
            url: "/city",
            data: {
                flightdate: flightdate,
                flightnum: flightnum,
            },
            success: function(result){
                var destinationB = new google.maps.LatLng(result.lat, result.long);
                // start google maps stuff
                // var service = new google.maps.DistanceMatrixService;
                service.getDistanceMatrix({
                    origins: [userlocation],
                    destinations: [destinationB],
                    travelMode: 'DRIVING',
                    avoidHighways: false,
                    avoidTolls: true,
                },
                function(response, status) {
                    if(status=="OK") {
                        var element = response.rows[0];
                        duration = element.elements[0];
                        // get detailed flight timing info with map info passed into it
                        $.ajax({
                            type: 'POST',
                            url: "/result",
                            data: {
                                flightdate: flightdate,
                                flightnum: flightnum,
                                mapdelay: duration,
                                usertime: today
                            },
                            success: function(result){
                                $("#container-warning").html("")
                                document.getElementById("spinner-div").style.visibility = "hidden";
                                $('#result-panel').html(result)
                            }
                        })
                    } else {
                        alert("Error: " + status);
                    }
                });
            },
            error: function(response){
                document.getElementById("spinner-div").style.visibility = "hidden";
                $("#container-warning").html('<div class="alert alert-warning alert-dismissible fade in" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><strong>Error:</strong> flight does not exist for that date. </div>')
            }
        })
    })
})
