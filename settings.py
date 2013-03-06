from shapely.geometry import box
slug = "restaurant-noaddr"
name = "Restaurants without an Address"
description = "Restaurants with no addresses"
difficulty = "beginner"
blurb = description
# polygon = box(minx, miny, maxx, maxy, ccw = True)
polygon = box(-90.0, -180.0, 90.0, 180.0)
help = """
# Place Addresses on Restaurants

Many restaurants in OpenStreetMap are missing addresses. This
challenge works to fix that by hilighting restaurants without an
address.

To fix a restaurant, load it up in your editor and add the following fields:

* `addr:street`
* `addr:housenumber`
* `addr:city`

In addition, you may want to add

* `website`

for the restaurant's website.
"""
