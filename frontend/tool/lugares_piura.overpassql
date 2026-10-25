[out:json][timeout:120];
(
  way["highway"]["name"](-5.30,-80.72,-5.12,-80.57);
  nwr["place"~"^(city|town|village|suburb|neighbourhood|quarter|hamlet)$"]["name"](-5.30,-80.72,-5.12,-80.57);
  nwr["amenity"~"^(school|university|college|hospital|clinic|marketplace|bus_station|place_of_worship|townhall|police)$"]["name"](-5.30,-80.72,-5.12,-80.57);
  nwr["shop"~"^(mall|supermarket)$"]["name"](-5.30,-80.72,-5.12,-80.57);
  nwr["leisure"~"^(park|stadium)$"]["name"](-5.30,-80.72,-5.12,-80.57);
);
out center tags;
