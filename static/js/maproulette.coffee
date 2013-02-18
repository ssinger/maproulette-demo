###
# This file contains all the MapRoulette client/javascript code
###
root = exports ? this

mr_attrib = "<small>thing by <a href='mailto:m@rtijn.org'>Martijn van Exel</a></small>"

map = undefined
geojsonLayer = new L.GeoJSON()
bingLayer = undefined
osmLayer = undefined
# Set default tile url and attribution
tileUrl = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
tileAttrib = '© <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
t = undefined
editor = ""
taskId = 0
osmObjType = ""
osmObjId = 0
selectedFeatureType = ""
selectedFeatureId = ""
help = ""

msgNextChallenge = 'Faites vos jeux...'
msgMovingOnToTheNextChallenge = 'OK, moving right along...'
msgZoomInForEdit = """Please zoom in a little so we don't have to load a huge area from the API."""
enablekeyboardhooks = true

getExtent = (feature) ->
  ###
  # Takes in a JSON feature and return a Leaflet LatLngBounds
  ###
  return false unless (feature.geometry.coordinates and
    feature.geometry.coordinates.length > 0)
  if feature.geometry.type is "Point"
    # This function is pointless for a point, but we'll support it anyway
    lng = feature.geometry.coordinates[0]
    lat = feature.geometry.coordinates[1]
    latlng = new L.LatLng(lat, lng)
    bounds = new L.LatLngBounds(latlng)
    bounds.extend(latlng)
    bounds
  else
    lats = []
    lngs = []
    for coordinates in feature.geometry.coordinates
      lats.push coordinates[1]
      lngs.push coordinates[0]
    minlat = Math.min.apply(Math, lats)
    sw = new L.LatLng(Math.min.apply(Math, lats), Math.min.apply(Math, lngs))
    ne = new L.LatLng(Math.max.apply(Math, lats), Math.max.apply(Math, lngs))
    new L.LatLngBounds(sw, ne)

@msgClose = ->
  ###
  # Close the msg box
  ###
  $("#msgBox").fadeOut()

msg = (html, timeout) ->
  ###
  # Display a msg (html) in the msgbox for time (timeout) seconds
  # unless timeout is 0
  ###
  clearTimeout timeout
  $("#msgBox").html(html).fadeIn()
  $("#msgBox").css "display", "block"
  setTimeout(msgClose, timeout * 1000) unless timeout == 0

dlg = (h) ->
  ###
  #  Display the data (html) in a dialog box. Must be closed with dlgClose()
  ###
  $("#dlgBox").html(h).fadeIn()
  $("#dlgBox").css "display", "block"

@dlgClose = ->
  ###
  # Closes the dialog box
  ###
  $("#dlgBox").fadeOut()

nomToString = (addr) ->
  ###
  # Takes a geocode object returned from Nominatim and returns a
  # nicely formatted string
  ###
  str = ""
  # If the address in in a city, we don't need the county. If it's a
  # town or smaller, display the locality, county
  if addr.city?
    locality = addr.city
  else
    # Let's try to get the name of the local town/hamlet
    if addr.town?
      town = addr.town
    else if addr.hamlet?
      town = addr.hamlet
    else
      town = "Somewhere in"
    if addr.county?
      if addr.county.toLowerCase().indexOf('county') > -1
        county = ", #{addr.county}"
      else
        county = ", #{addr.county} County"
    else
      county = ""
    locality = "#{addr.town} #{county}"
  # Now we look for the state, or the nation
  if addr.state?
    "#{locality}, #{addr.state}"
  else
    if addr.country?
      "#{locality}, #{addr.country}"
    else
      "Somewhere on Earth"

revGeocodeOSMObj = (type, id) ->
  ###
  # Reverse geocodes an OSM object
  ###
  mqurl = "http://open.mapquestapi.com/nominatim/v1/reverse?format=json&osm_type=#{type}@osm_id=#{id}"
  msgClose
  $.getJSON mqurl, (data) ->
    locstr = nomToString(data.address)
    msg locstr, 3

revGeocode = ->
  ###
  # Reverse geocodes the center of the (currently displayed) map
  ###
  mqurl = "http://open.mapquestapi.com/nominatim/v1/reverse?format=json&lat=" + map.getCenter().lat + " &lon=" + map.getCenter().lng

  #close any notifications that are still hanging out on the page.
  msgClose()

  # this next bit fires the RGC request and parses the result in a
  # decent way, but it looks really ugly.
  $.getJSON mqurl, (data) ->
    locstr = nomToString(data.address)
    # display a message saying where we are in the world
    msg locstr, 3


@getItem = ->
  ###
  # Gets the next task and displays it
  ###
  # Do we really need to show this message?
  #msg msgNextChallenge, 0
  $.getJSON "/task", (data) ->
    text = data.text
    features = data.features.features
    taskId = data.id
    # This code needs to be generalized!!! (maybe put it in the
    # features section)
    osmObjType = data.type
    osmObjId = data.id
    points = []
    lines = []
    polygons = []
    return false  if not features? or features.length is 0 or not features
    for feature in features
      if feature.properties.selected is true
        osmObjId = feature.properties.id
        osmObjType = feature.properties.type
      geojsonLayer.addData feature
    extent = getExtent(features[0])
    map.fitBounds(extent)
    # revGeoCode()
    revGeocode()
    updateCounter()

initmap = ->
  ###
  # Initialize Leaflet map and layers
  ###
  map = new L.Map "map"
  osmLayer = new L.TileLayer(tileUrl, attribution: tileAttrib)
  map.setView new L.LatLng(40.0, -90.0), 17
  map.addLayer osmLayer
  # We need an onEachFeature function to create markers
  geojsonLayer = new L.geoJson(null, {
      onEachFeature: (feature, layer) ->
        if feature.properties and feature.properties.text
          layer.bindPopup(feature.properties.text)
          layer.openPopup()})
  map.addLayer geojsonLayer

  # get the first error
  getItem()

  # add keyboard hooks
  if enablekeyboardhooks
    $(document).bind "keydown", (e) ->
      switch e.which
        when 81 #q
          nextUp "falsepositive"
        when 87 #w
          nextUp "skip"
        when 69 #e
          openIn('josm')
        when 82 #r
          openIn('potlatch')
        when 73 #i
          openIn('id')

    # Update the counter
    updateCounter()

@nextUp = (action) ->
  ###
  # Display a message that we're moving on to the next error, store
  # the result of the confirmation dialog in the database, and load
  # the next challenge
  ###
  msg msgMovingOnToTheNextChallenge, 1
  payload = {
      "action": action,
      "editor": editor}
  $.post "/task/#{taskId}", payload, -> setTimeout getItem, 1000

@openIn = (e) ->
  ###
  # Open the currently displayed OSM objects in the selected editor (e)
  ###
  editor = e
  if map.getZoom() < 14
    msg msgZoomInForEdit, 3
    return false
  bounds = map.getBounds()
  sw = bounds.getSouthWest()
  ne = bounds.getNorthEast()
  if editor is "josm"
    JOSMurl =  "http://127.0.0.1:8111/load_and_zoom?left=#{sw.lng}&right=#{ne.lng}&top=#{ne.lat}&bottom=#{sw.lat}&new_layer=0&select=#{osmObjType}#{osmObjId}"
    # Use the .ajax JQ method to load the JOSM link unobtrusively and
    # alert when the JOSM plugin is not running.
    $.ajax
      url: JOSMurl
      complete: (t) ->
        if t.status is 200
          setTimeout confirmRemap, 4000
        else
          msg "JOSM remote control did not respond (" + t.status + "). Do you have JOSM running?", 2

  else if editor is "potlatch"
    PotlatchURL = "http://www.openstreetmap.org/edit?editor=potlatch2&bbox=" + map.getBounds().toBBoxString()
    window.open PotlatchURL
    setTimeout confirmRemap, 4000
  else if editor is "id"
    if osmObjType == "node"
      id = "n#{osmObjId}"
    else if osmObjType == "way"
      id = "w#{osmObjId}"
    # Sorry, no relation support in iD (yet?)
    loc = "#{map.getZoom()}/#{map.getCenter().lat}/#{map.getCenter().lng}"
    window.open "http://geowiki.com/iD/#id=#{id}&map=#{loc}"
    confirmRemap()

@confirmRemap = () ->
  ###
  # Show the confirmation dialog box
  ###
  if editor == 'josm'
    editorText = 'JOSM'
  else if editor == 'potlatch'
    editorText = 'Potlatch'
  else if editor == 'id'
    editorText = 'iD'

  dlg("""
The area is being loaded in #{editorText} now.
Come back here after you do your edits.<br />
  <br />
  Did you fix it?
  <p>
  <div class=button onClick=nextUp("fixed");$('#dlgBox').fadeOut()>YES</div>
  <div class=button onClick=nextUp("notfixed");$('#dlgBox').fadeOut()>NO :(</div>
  <div class=button onClick=nextUp("someonebeatme");$('#dlgBox').fadeOut()>SOMEONE BEAT ME TO IT</div>
  <div class=button onClick=nextUp("noerrorafterall");$('#dlgBox').fadeOut()>IT WAS NOT AN ERROR AFTER ALL</div>
  </p>
  """)

@showHelp = ->
  ###
  # Show the about window
  ###
  dlg """#{help}
  <p>#{mr_attrib}</p>
  <p><div class='button' onClick="dlgClose()">OK</div></p>""", 0

updateCounter = ->
  ###
  # Get the stats for the current challenge and display the count of
  # remaining tasks
  ###
  $.getJSON "/stats", (data) ->
    remaining = data.total - data.done
    $("#counter").text remaining

@init = ->
  ###
  # Use the challenge metadata to fill in the web page
  ###
  $.getJSON "/meta", (data) ->
    help = data.help
    $('#challengeDetails').text data.blurb
    tileURL = data.tileurl if data.tileurl?
    tileAttrib = data.tileasttribution if data.tileattribution?
    initmap()
