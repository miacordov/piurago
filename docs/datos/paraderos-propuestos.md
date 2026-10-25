# Paraderos propuestos

Propuesta de paraderos para las 20 líneas de `rutas-piuratransporta.json`. **No son paraderos oficiales**: son lugares conocidos que quedan a menos de 200 m del recorrido, según [PiuraTransporta](https://piuratransporta.com/rutas), con coordenadas de OpenStreetMap (© OpenStreetMap contributors, licencia ODbL). Datos consultados el 24/10/2026.

Datos completos (coordenadas y orden por ruta): [`paraderos-propuestos.json`](paraderos-propuestos.json). La app los usa desde `frontend/lib/data/paraderos_propuestos.dart`.

## Lugares más concurridos

Cuantas más líneas pasan junto a un lugar, más pasajeros suben, bajan o transbordan allí. Por eso son los mejores candidatos para los primeros paraderos.

| # | Lugar | Líneas | Códigos | Latitud | Longitud |
|---|---|---|---|---|---|
| 1 | Mercado Modelo | 13 | I-19, RD-01, RD-05, RD-08, RD-09, RD-11, RD-15, RD-18, RD-20, RD-21, RD-22, U-03, U-04 | -5.18864 | -80.63387 |
| 2 | Open Plaza | 12 | I-19, RD-01, RD-02, RD-08, RD-09, RD-10, RD-15, RD-16, RD-19, RD-22, U-03, U-04 | -5.18171 | -80.62217 |
| 3 | Real Plaza | 11 | I-19, RD-01, RD-05, RD-08, RD-09, RD-15, RD-16, RD-18, RD-19, RD-21, U-03 | -5.1847 | -80.64196 |
| 4 | I.E. Nuestra Señora de Fatima | 10 | I-19, RD-01, RD-05, RD-08, RD-09, RD-15, RD-20, RD-21, RD-22, U-04 | -5.18962 | -80.63691 |
| 5 | Plazuela Merino | 10 | I-19, RD-01, RD-03, RD-05, RD-08, RD-20, RD-21, RD-22, U-03, U-04 | -5.19325 | -80.6255 |
| 6 | Univ. Nacional de Piura | 10 | I-19, RD-01, RD-02, RD-03, RD-09, RD-10, RD-15, RD-22, U-03, U-04 | -5.17754 | -80.61776 |
| 7 | Estadio Miguel Grau | 9 | RD-01, RD-03, RD-05, RD-11, RD-19, RD-20, RD-22, U-03, U-04 | -5.19274 | -80.61709 |
| 8 | Plaza Tres Culturas | 5 | I-19, RD-08, RD-11, RD-18, RD-20 | -5.19851 | -80.62585 |
| 9 | Mercado de Castilla | 5 | I-19, RD-03, RD-08, RD-11, RD-20 | -5.19988 | -80.62278 |
| 10 | I.E. Militar Pedro Ruiz Gallo | 5 | RD-01, RD-05, RD-09, RD-11, RD-22 | -5.18827 | -80.60056 |
| 11 | Parque Miguel Cortés/Infantil | 5 | RD-03, RD-11, RD-15, RD-18, RD-21 | -5.19548 | -80.63199 |
| 12 | Plaza del Sol (Av. Grau-Gulman) | 5 | RD-15, RD-18, RD-20, RD-21, U-04 | -5.19248 | -80.63955 |
| 13 | Instituto Médico Soy Diabético | 4 | RD-02, RD-10, RD-16, RD-19 | -5.18321 | -80.62606 |
| 14 | Plaza de Armas | 4 | RD-02, RD-10, RD-14, RD-18 | -5.19712 | -80.62662 |
| 15 | Establecimiento de Salud I-4 Pachitea | 3 | RD-02, RD-14, RD-16 | -5.18608 | -80.63116 |
| 16 | Parque Néstor Martos Garridos | 3 | RD-05, RD-09, RD-21 | -5.18995 | -80.64407 |
| 17 | Hospital Jorge Reátegui Delgado | 3 | RD-20, RD-21, U-04 | -5.19319 | -80.63634 |

La lista completa (43 lugares) está en el JSON, en `lugaresMasConcurridos`.

## Cómo se armó

1. Por cada línea se tomaron los lugares destacados que publica PiuraTransporta y sus extremos (sale de / llega a).
2. Las coordenadas salen de OpenStreetMap: Overpass para los lugares con nombre y Nominatim para los extremos.
3. Como la web no publica el trazado, el orden de los paraderos se calculó por cercanía. Se parte del extremo inicial, o del primer lugar si no hay extremo, y se va al lugar más próximo.

## Qué validar antes de usarlos

- **Orden y trazado:** el orden por cercanía es una aproximación. En el mapa la línea puede zigzaguear o no seguir las calles reales.
- **Ubicación exacta:** la coordenada es la del lugar (a veces el centro de un campus o del aeropuerto), no la esquina donde para la combi.
- **Nombres dudosos:**
  - I.E. Nuestra Señora del Carmen: Hay dos con ese nombre: se eligió la que está camino a La Unión.
  - Open Plaza: En OSM figura como Mallplaza Piura (antes Open Plaza): verificar.
  - Plaza del Sol (Centro): Hay dos Plaza del Sol: esta es la del centro.
  - Aeropuerto de Piura: Coordenada del centro del aeropuerto: el paradero va en la entrada.
  - Univ. de Piura (UDEP): Coordenada del centro del campus: el paradero va en la puerta.
  - Plaza del Sol (Av. Grau-Gulman): Hay dos Plaza del Sol: esta es la de Av. Grau con Gulman.
  - Terminal Terrestre: Hay varios terminales: se eligió el Terminal Terrestre de Castilla, verificar.
  - I.E. Maria Auxiliadora: Hay tres con ese nombre: se eligió la de Castilla, cerca de El Indio.
- **Extremos sin coordenadas:** no se ubicaron en OSM "Piura" y "Veintiséis de Octubre" (demasiado genéricos), Parcela J, las avenidas Raúl Mata La Cruz y José Aguilar Santisteban, la Vía Colectora Norte ni el Centro histórico. Las Lomas y La Unión quedan fuera de la ciudad. Ninguno tiene paradero de extremo.
- **Rutas sin extremos:** RD-01, RD-03, RD-09, RD-15, RD-18 y U-04 no indican de dónde salen ni a dónde llegan, así que solo tienen los lugares intermedios.
- **I-18:** solo tiene 2 paraderos, porque la web publica un único lugar destacado para esa línea.
