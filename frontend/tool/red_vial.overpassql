[out:json][timeout:300];
(
  way["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|road|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link|service)$"](-5.36,-80.76,-5.10,-80.55);
  way["highway"~"^(trunk|primary|secondary|tertiary|unclassified|trunk_link|primary_link|secondary_link)$"](-5.60,-80.90,-4.55,-80.10);
);
out body geom;
