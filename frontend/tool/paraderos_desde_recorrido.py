"""Calcula paraderos PROPUESTOS a partir del recorrido oficial de una ruta.

El recorrido oficial es la lista de calles en orden (nota de prensa de la
Municipalidad Provincial de Piura del 7/6/2024). Cada paradero se pone en el
CRUCE REAL entre una calle y la siguiente, con la geometría de
OpenStreetMap (© colaboradores de OpenStreetMap, ODbL): no se inventan
calles. Si una calle no está en OpenStreetMap, se salta y se busca el cruce
con la siguiente. Los extremos son las zonas de inicio y fin, si existen.

Uso (desde frontend/):
    curl -s -A "PiuraGo/0.1 (proyecto universitario UTP)" \\
      --data-urlencode "data@tool/calles_piura_geom.overpassql" \\
      https://overpass-api.de/api/interpreter -o /tmp/calles.json
    python3 tool/paraderos_desde_recorrido.py /tmp/calles.json /tmp/osm.json \\
      ../docs/datos/paraderos-plan-regulador.json
(/tmp/osm.json es la descarga de tool/lugares_piura.overpassql).
"""

import json
import math
import sys
import unicodedata

# Distancia máxima entre dos calles para considerar que se cruzan aunque
# no compartan un nodo en OpenStreetMap.
CRUCE_CERCANO_M = 60
# Un tramo más largo que esto entre paraderos consecutivos es sospechoso.
TRAMO_MAXIMO_M = 3500

# Recorridos oficiales. Cada elemento es ('calle', texto que debe contener el
# nombre en OSM, nombre para mostrar) o ('zona', nombre del lugar en OSM).
RECORRIDOS = {
    'RD-12': [
        ('calle', 'via de evitamiento este', 'Vía de Evitamiento Este'),
        ('calle', 'avenida los jardines', 'Av. Los Jardines'),
        ('calle', 'calle bolognesi', 'Calle Bolognesi'),
        ('calle', 'calle lalaquiz', 'Calle Lalaquiz'),
        ('calle', 'avenida los almendros', 'Av. Los Almendros'),
        ('calle', 'avenida guardia civil', 'Av. Guardia Civil'),
        ('calle', 'avenida andres avelino caceres', 'Av. Andrés A. Cáceres'),
        ('calle', 'avenida independencia', 'Av. Independencia'),
        ('calle', 'avenida luis antonio eguiguren', 'Av. Luis A. Eguiguren'),
        ('calle', 'avenida loreto', 'Av. Loreto'),
        ('calle', 'calle alameda peru', 'Av. Alameda Perú'),
    ],
    'RD-17': [
        ('zona', 'Villa Perú Canadá'),
        ('calle', 'avenida juan velasco alvarado', 'Av. Juan Velasco Alvarado'),
        ('calle', 'avenida santa rosa', 'Av. Santa Rosa'),
        ('calle', 'avenida bellavista', 'Av. Bellavista'),
        ('calle', 'avenida grau', 'Av. Grau'),
        ('calle', 'avenida marcavelica', 'Av. Marcavelica'),
        ('calle', 'avenida sanchez cerro', 'Av. Sánchez Cerro'),
        ('calle', 'avenida vice', 'Av. Vice'),
        ('calle', 'calle victor a. belaunde', 'Víctor Andrés Belaunde'),
        ('calle', 'jiron b', 'Jirón B'),
        ('calle', 'avenida sullana', 'Av. Sullana'),
        ('calle', 'avenida luis antonio eguiguren', 'Av. Luis A. Eguiguren'),
        ('calle', 'avenida country', 'Av. Country'),
        ('calle', 'avenida fortunato chirichigno', 'Av. Fortunato Chirichigno'),
        ('calle', 'avenida las palmeras', 'Av. Las Palmeras'),
        ('calle', 'calle los manzanos', 'Calle Los Manzanos'),
        ('calle', 'gardenias', 'Gardenias'),
        ('calle', 'colectora', 'Av. Colectora'),
        ('zona', 'Las Lomas del Chipe'),
    ],
}


def normalizar(texto):
    sin_tildes = unicodedata.normalize('NFD', texto.lower())
    return ''.join(c for c in sin_tildes if unicodedata.category(c) != 'Mn')


def distancia(a, b):
    lat1, lon1 = map(math.radians, a)
    lat2, lon2 = map(math.radians, b)
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    return 2 * 6371000 * math.asin(min(1, math.sqrt(h)))


def nodos_de_calle(vias, texto):
    """Puntos (lat, lon) de todas las vías cuyo nombre contiene el texto. Si
    hay un nombre exacto, solo ese."""
    exactas = [w for w in vias if normalizar(w['tags'].get('name', '')) == texto]
    elegidas = exactas or [w for w in vias
                           if texto in normalizar(w['tags'].get('name', ''))]
    return [(p['lat'], p['lon']) for w in elegidas for p in w.get('geometry', [])]


def cruce(nodos_a, nodos_b, cerca_de):
    """Punto donde se cruzan dos calles (el más cercano a `cerca_de`)."""
    candidatos = []
    conjunto_b = set(nodos_b)
    for p in nodos_a:
        if p in conjunto_b:
            candidatos.append(p)
    if not candidatos:
        for p in nodos_a:
            for q in nodos_b:
                if distancia(p, q) <= CRUCE_CERCANO_M:
                    candidatos.append(p)
    if not candidatos:
        return None
    if cerca_de is None:
        return candidatos[0]
    return min(candidatos, key=lambda p: distancia(p, cerca_de))


def main(archivo_calles, archivo_lugares, salida):
    vias = [e for e in json.load(open(archivo_calles))['elements'] if e['type'] == 'way']
    zonas = {}
    for e in json.load(open(archivo_lugares))['elements']:
        etiquetas = e.get('tags', {})
        if 'name' in etiquetas and etiquetas.get('place'):
            pos = (e['center']['lat'], e['center']['lon']) if 'center' in e else (e['lat'], e['lon'])
            zonas.setdefault(etiquetas['name'], pos)

    resultado = {}
    for codigo, recorrido in RECORRIDOS.items():
        paraderos = []
        ultimo = None
        anterior = None  # (nodos, nombre) de la última calle encontrada
        for paso in recorrido:
            if paso[0] == 'zona':
                pos = zonas.get(paso[1])
                if pos:
                    paraderos.append({'nombre': paso[1], 'lat': pos[0], 'lon': pos[1]})
                    ultimo = pos
                else:
                    print(f'{codigo}: no está la zona {paso[1]}')
                continue
            nodos = nodos_de_calle(vias, paso[1])
            if not nodos:
                print(f'{codigo}: no está la calle {paso[2]}')
                continue
            if anterior:
                punto = cruce(anterior[0], nodos, ultimo)
                if punto:
                    if ultimo and distancia(ultimo, punto) > TRAMO_MAXIMO_M:
                        print(f'{codigo}: tramo largo hasta {anterior[1]} / {paso[2]} '
                              f'({distancia(ultimo, punto):.0f} m)')
                    paraderos.append({
                        'nombre': f'{anterior[1]} / {paso[2]}',
                        'lat': punto[0], 'lon': punto[1],
                    })
                    ultimo = punto
                else:
                    print(f'{codigo}: {anterior[1]} y {paso[2]} no se cruzan en OSM')
            anterior = (nodos, paso[2])
        for orden, p in enumerate(paraderos, start=1):
            p['orden'] = orden
            p['lat'] = round(p['lat'], 5)
            p['lon'] = round(p['lon'], 5)
        resultado[codigo] = paraderos
        print(f'{codigo}: {len(paraderos)} paraderos')

    json.dump(resultado, open(salida, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])
