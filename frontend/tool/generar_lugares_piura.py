"""Genera lib/data/lugares/lugares_piura.dart: la base propia de calles, zonas
y lugares conocidos de Piura, Castilla y Veintiséis de Octubre que usa el
buscador "¿A dónde vas?" (como la base propia de piuratransporta.com).

Los datos son de OpenStreetMap (© colaboradores de OpenStreetMap, licencia
ODbL). Se descargan una sola vez con la consulta de lugares_piura.overpassql;
al buscar, la app no consulta este servicio.

Uso (desde frontend/):
    curl -s -A "PiuraGo/0.1 (proyecto universitario UTP)" \\
      --data-urlencode "data@tool/lugares_piura.overpassql" \\
      https://overpass-api.de/api/interpreter -o /tmp/osm.json
    python3 tool/generar_lugares_piura.py /tmp/osm.json lib/data/lugares/lugares_piura.dart
    dart format lib/data/lugares/lugares_piura.dart
"""

import json
import math
import sys
import unicodedata
from datetime import date

# Vías que no sirven para ubicarse (veredas, escaleras, obras...).
VIAS_EXCLUIDAS = {
    'footway', 'path', 'steps', 'cycleway', 'track', 'corridor', 'proposed',
    'construction', 'bridleway', 'platform', 'bus_stop', 'elevator',
}
# Las calles más importantes van primero en las sugerencias.
RANGO_VIA = {
    'trunk': 0, 'primary': 0, 'secondary': 1, 'tertiary': 2,
    'unclassified': 3, 'residential': 3, 'living_street': 3, 'pedestrian': 3,
}
# Tramos de una misma calle a más de esta distancia son calles distintas
# (por ejemplo, "Avenida Grau" en Castilla y en Veintiséis de Octubre).
DISTANCIA_MISMA_CALLE_M = 1500
# Zonas para decir dónde queda cada lugar.
ZONAS = {'suburb', 'neighbourhood', 'quarter', 'hamlet', 'village', 'town', 'city'}


def distancia(a, b):
    """Distancia en metros (Haversine)."""
    lat1, lon1 = map(math.radians, a)
    lat2, lon2 = map(math.radians, b)
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    return 2 * 6371000 * math.asin(min(1, math.sqrt(h)))


def normalizar(texto):
    sin_tildes = unicodedata.normalize('NFD', texto.lower())
    return ''.join(c for c in sin_tildes if unicodedata.category(c) != 'Mn').strip()


def posicion(elemento):
    if 'center' in elemento:
        return (elemento['center']['lat'], elemento['center']['lon'])
    return (elemento['lat'], elemento['lon'])


def agrupar(tramos):
    """Une los tramos de una calle que están cerca entre sí."""
    grupos = []
    for tramo in tramos:
        cercanos = [g for g in grupos
                    if any(distancia(tramo['pos'], t['pos']) <= DISTANCIA_MISMA_CALLE_M
                           for t in g)]
        nuevo = [tramo]
        for g in cercanos:
            nuevo.extend(g)
            grupos.remove(g)
        grupos.append(nuevo)
    return grupos


def punto_central(grupo):
    """Centro del tramo más cercano al centro del grupo: cae sobre la calle."""
    lat = sum(t['pos'][0] for t in grupo) / len(grupo)
    lon = sum(t['pos'][1] for t in grupo) / len(grupo)
    return min(grupo, key=lambda t: distancia(t['pos'], (lat, lon)))['pos']


def main(entrada, salida):
    elementos = json.load(open(entrada, encoding='utf-8'))['elements']

    zonas, otros, tramos = [], [], {}
    for e in elementos:
        etiquetas = e.get('tags', {})
        nombre = etiquetas.get('name', '').strip()
        if not nombre:
            continue
        via = etiquetas.get('highway')
        if via:
            if via in VIAS_EXCLUIDAS or e['type'] != 'way':
                continue
            tramos.setdefault(nombre, []).append(
                {'pos': posicion(e), 'rango': RANGO_VIA.get(via, 4)})
        elif etiquetas.get('place') in ZONAS:
            zonas.append((nombre, posicion(e)))
        else:
            otros.append((nombre, posicion(e)))

    def detalle(nombre, pos):
        """Zona más cercana (que no sea el mismo lugar), y la ciudad."""
        candidatas = [z for z in zonas if normalizar(z[0]) != normalizar(nombre)]
        if not candidatas:
            return 'Piura'
        zona = min(candidatas, key=lambda z: distancia(z[1], pos))[0]
        return 'Piura' if zona == 'Piura' else f'{zona}, Piura'

    calles = []
    for nombre, lista in tramos.items():
        for grupo in agrupar(lista):
            calles.append({
                'nombre': nombre,
                'pos': punto_central(grupo),
                'rango': min(t['rango'] for t in grupo),
                'tramos': len(grupo),
            })
    calles.sort(key=lambda c: (c['rango'], -c['tramos'], normalizar(c['nombre'])))

    vistos = set()
    lugares = []

    def agregar(nombre, pos, tipo):
        texto_detalle = detalle(nombre, pos)
        clave = (normalizar(nombre), texto_detalle)
        if clave in vistos:
            return
        vistos.add(clave)
        lugares.append((nombre, pos, tipo, texto_detalle))

    for c in calles:
        agregar(c['nombre'], c['pos'], 'calle')
    for nombre, pos in otros:
        agregar(nombre, pos, 'lugar')
    for nombre, pos in zonas:
        agregar(nombre, pos, 'zona')

    def literal(texto):
        return "'" + texto.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"

    lineas = [
        "import 'package:latlong2/latlong.dart';",
        '',
        "import '../models/lugar.dart';",
        '',
        '/// Base propia de calles, zonas y lugares conocidos de Piura, Castilla y',
        '/// Veintiséis de Octubre para el buscador "¿A dónde vas?". Primero las',
        '/// calles más importantes.',
        '///',
        '/// Datos de OpenStreetMap (© colaboradores de OpenStreetMap, licencia ODbL),',
        f'/// descargados el {date.today().strftime("%d/%m/%Y")}. Cada calle tiene un solo punto',
        '/// (sobre la calle, cerca de su centro). Archivo generado por',
        '/// tool/generar_lugares_piura.py: no editar a mano.',
        'const lugaresPiura = <Lugar>[',
    ]
    for nombre, (lat, lon), tipo, texto_detalle in lugares:
        lineas.append(
            f'  Lugar({literal(nombre)}, LatLng({lat:.5f}, {lon:.5f}), '
            f'tipo: TipoLugar.{tipo}, detalle: {literal(texto_detalle)}),')
    lineas.append('];')
    open(salida, 'w', encoding='utf-8').write('\n'.join(lineas) + '\n')
    cuenta = {t: sum(1 for l in lugares if l[2] == t) for t in ('calle', 'zona', 'lugar')}
    print(f'{len(lugares)} lugares: {cuenta}')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
