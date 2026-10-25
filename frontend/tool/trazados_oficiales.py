"""Trazados y paraderos de las rutas con recorrido OFICIAL de la Municipalidad
Provincial de Piura (nota del 7/6/2024, ver docs/datos/rutas-plan-regulador.md).

Para cada ruta:
1. Recorre las calles oficiales EN ORDEN. Donde una calle cruza a la
   siguiente (nodo compartido en OpenStreetMap, ODbL) pone un paradero; si no
   se cruzan, entra a la calle por su punto más cercano.
2. Une esos puntos por la red vial real (camino más corto), con preferencia
   por las calles oficiales de la ruta: el trazado sigue calles de punta a
   punta. Solo es línea recta donde la red no llega (se informa).
3. Confirma los paraderos propuestos que ya tenía la ruta: se quedan los que
   están a menos de CONFIRMA_M del trazado; los demás se descartan.

Uso (desde frontend/), con las descargas de tool/*.overpassql:
    python3 tool/trazados_oficiales.py red-vial.json pueblos.json lugares.json \\
        ../docs/datos/paraderos-propuestos.json \\
        ../docs/datos/trazados-oficiales.json lib/data/trazados_oficiales.dart
    dart format lib/data/trazados_oficiales.dart
"""

import heapq
import os
import json
import math
import sys
import unicodedata

CONFIRMA_M = 200
DUPLICADO_M = 80
SIMPLIFICA_M = 8
# Si la calle más cercana con ese nombre está más lejos que esto del punto
# anterior, es otra calle homónima: se omite en lugar de desviar el trazado
# (salvo la última, que es el destino de la ruta).
CALLE_LEJANA_M = 2500
ID_PARADERO_INICIAL = 1001

# Ids de las rutas en la app (rutas_repository.dart).
IDS = {
    'RD-05': None, 'RD-10': None, 'RD-11': None, 'RD-12': 22, 'RD-14': None,
    'RD-16': None, 'RD-17': 24, 'RD-19': None, 'RD-20': None, 'RD-21': None,
}

C = 'calle'
L = 'lugar'
P = 'punto'

# Recorridos oficiales (nota de la Municipalidad del 7/6/2024), con los
# nombres de OpenStreetMap. Lo que no está en OSM queda en comentario.
RECORRIDOS = {
    'RD-05': [
        # Parcela J: no está en OSM.
        (C, ['Avenida Sánchez Cerro'], 'Av. Sánchez Cerro'),
        (C, ['Avenida Guardia Civil'], 'Av. Guardia Civil'),
        (L, 'Alto Grande'), (L, 'Locuto'), (L, 'Ocoto Alto'),
        # Hada: no está en OSM.
        (L, 'Tambogrande'), (L, 'La Cruceta'), (L, 'El Partidor'), (L, 'Las Lomas'),
    ],
    'RD-10': [
        (L, 'Upis San Gabriel Arcángel'),
        (C, ['Vía de Evitamiento Este'], 'Vía de Evitamiento Este'),
        (C, ['Avenida Guardia Civil'], 'Av. Guardia Civil'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Avenida Sullana'], 'Av. Sullana'),
        (C, ['Avenida Sánchez Cerro'], 'Av. Sánchez Cerro'),
        (C, ['Avenida Loreto'], 'Av. Loreto'),
        (C, ['Avenida Grau', 'Avenida Miguel Grau'], 'Av. Grau'),
        (C, ['Avenida Richard Cushing'], 'Av. Richard Cushing'),
        (C, ['Calle Sáenz Peña'], 'Calle Sáenz Peña'),
        (C, ['Calle Puerto Rico'], 'Calle Puerto Rico'),
        (C, ['Calle Santo Domingo'], 'Calle Santo Domingo'),
        # Av. Guillermo Gulman: no está en OSM.
        (C, ['Calle Yugoslavia'], 'Calle Yugoslavia'),
        (C, ['Calle Las Américas', 'Calle las Américas'], 'Calle Las Américas'),
        (C, ['Calle China Popular'], 'Calle China Popular'),
        (C, ['Avenida Nicaragua'], 'Av. Nicaragua'),
        # Av. Raúl Mata La Cruz: no está en OSM.
    ],
    'RD-11': [
        (L, 'Asentamiento Humano Los Almendros'),
        (C, ['Avenida Integración'], 'Av. Integración'),
        (C, ['Avenida Los Almendros'], 'Av. Los Almendros'),
        (C, ['Avenida Guardia Civil'], 'Av. Guardia Civil'),
        (C, ['Avenida Cayetano Heredia'], 'Av. Cayetano Heredia'),
        (C, ['Avenida Ramón Castilla', 'Avenida Ramon Castilla'], 'Av. Ramón Castilla'),
        (C, ['Avenida Tacna'], 'Av. Tacna'),
        (C, ['Avenida Bolognesi'], 'Av. Bolognesi'),
        (C, ['Avenida Sullana'], 'Av. Sullana'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Avenida Ignacio Merino', 'Calle Ignacio Merino'], 'Av. Ignacio Merino'),
        (C, ['Avenida José E. Aguilar Santisteban'], 'Av. José Aguilar Santisteban'),
    ],
    'RD-12': [
        (C, ['Vía de Evitamiento Este'], 'Vía de Evitamiento Este'),
        (C, ['Avenida Los Jardines'], 'Av. Los Jardines'),
        (C, ['Calle Bolognesi'], 'Calle Bolognesi'),
        (C, ['Calle Lalaquiz'], 'Calle Lalaquiz'),
        (C, ['Avenida Los Almendros'], 'Av. Los Almendros'),
        (C, ['Avenida Guardia Civil'], 'Av. Guardia Civil'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Avenida Independencia'], 'Av. Independencia'),
        (C, ['Avenida Luis Antonio Eguiguren'], 'Av. Luis A. Eguiguren'),
        (C, ['Avenida Loreto'], 'Av. Loreto'),
        (C, ['Calle Alameda Perú'], 'Av. Alameda Perú'),
    ],
    'RD-14': [
        (L, 'El Indio'),
        (C, ['Avenida Sánchez Carrión'], 'Av. Sánchez Carrión'),
        (C, ['Avenida Miguel Grau'], 'Av. Miguel Grau'),
        (C, ['Avenida Junín'], 'Av. Junín'),
        (C, ['Avenida Tacna'], 'Av. Tacna'),
        (C, ['Avenida Bolognesi'], 'Av. Bolognesi'),
        (C, ['Avenida Loreto'], 'Av. Loreto'),
        (C, ['Jirón San Cristóbal'], 'Jr. San Cristóbal'),
        (C, ['Avenida San Ramón'], 'Av. San Ramón'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        # Av. Ramón Mujica: no está en OSM.
        (C, ['Avenida Fortunato Chirichigno'], 'Av. Fortunato Chirichigno'),
        (C, ['Avenida Los Tallanes'], 'Av. Los Tallanes'),
        (C, ['Carretera Piura - Curumuy'], 'Carretera a Curumuy'),
        (L, 'Ejidos de Huan'),
    ],
    'RD-16': [
        (C, ['Avenida La Alameda de los Ficus'], 'Av. Alameda de los Ficus'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Avenida Country'], 'Av. Country'),
        (C, ['Avenida Sullana'], 'Av. Sullana'),
        (C, ['Calle Víctor A. Belaúnde'], 'Víctor Andrés Belaunde'),
        (C, ['Avenida Vice'], 'Av. Vice'),
        (C, ['Jirón Tambogrande'], 'Jr. Tambogrande'),
        (C, ['Jirón Tangarará'], 'Jr. Tangarará'),
        # Jr. Enrique del Villar: no está en OSM.
        (C, ['Avenida Grau', 'Avenida Miguel Grau'], 'Av. Grau'),
        (C, ['Avenida Marcavelica'], 'Av. Marcavelica'),
        (L, 'Nuevo Horizonte'),
    ],
    'RD-17': [
        (L, 'Villa Perú Canadá'),
        (C, ['Avenida Juan Velasco Alvarado'], 'Av. Juan Velasco Alvarado'),
        (C, ['Avenida Santa Rosa'], 'Av. Santa Rosa'),
        (C, ['Avenida Bellavista'], 'Av. Bellavista'),
        (C, ['Avenida Grau', 'Avenida Miguel Grau'], 'Av. Grau'),
        (C, ['Avenida Marcavelica'], 'Av. Marcavelica'),
        (C, ['Avenida Sánchez Cerro'], 'Av. Sánchez Cerro'),
        (C, ['Avenida Vice'], 'Av. Vice'),
        (C, ['Calle Víctor A. Belaúnde'], 'Víctor Andrés Belaunde'),
        (C, ['Jirón B'], 'Jirón B'),
        (C, ['Avenida Sullana'], 'Av. Sullana'),
        (C, ['Avenida Luis Antonio Eguiguren'], 'Av. Luis A. Eguiguren'),
        (C, ['Avenida Country'], 'Av. Country'),
        (C, ['Avenida Fortunato Chirichigno'], 'Av. Fortunato Chirichigno'),
        (C, ['Avenida Las Palmeras'], 'Av. Las Palmeras'),
        (C, ['Calle los Manzanos'], 'Calle Los Manzanos'),
        (C, ['Gardenias', 'Avenida Las Gardenias'], 'Gardenias'),
        (C, ['Avenida Vía Colectora Norte', 'Avenida Integradora Colectora'], 'Av. Colectora'),
        (L, 'Las Lomas del Chipe'),
    ],
    'RD-19': [
        (L, 'El Indio'),
        (C, ['Avenida las Flores'], 'Av. Las Flores'),
        (C, ['Calle Mariano Melgar', 'Mariano Melgar'], 'Calle Mariano Melgar'),
        (C, ['Avenida Progreso'], 'Av. Progreso'),
        (C, ['Avenida Luis Montero'], 'Av. Luis Montero'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Avenida Country'], 'Av. Country'),
        (C, ['Avenida Luis Antonio Eguiguren'], 'Av. Luis A. Eguiguren'),
        (C, ['Avenida Sullana'], 'Av. Sullana'),
        (C, ['Avenida Andrés Avelino Cáceres'], 'Av. Andrés A. Cáceres'),
        (C, ['Jirón Los Incas'], 'Jr. Los Incas'),
        (C, ['Avenida Los Diamantes', 'Avenida los Diamantes'], 'Av. Los Diamantes'),
        (C, ['Avenida Integradora Colectora'], 'Av. Integradora Norte'),
        (C, ['Avenida Vía Colectora Norte'], 'Vía Colectora'),
    ],
    'RD-20': [
        (L, 'Chiclayito'),
        (C, ['Calle los Andes', 'Jirón Los Andes'], 'Calle Los Andes'),
        (C, ['Avenida Ignacio Merino', 'Calle Ignacio Merino'], 'Av. Ignacio Merino'),
        (C, ['Avenida Progreso'], 'Av. Progreso'),
        (C, ['Calle Arequipa', 'Jirón Arequipa', 'Arequipa'], 'Calle Arequipa'),
        (C, ['Avenida Miguel Grau'], 'Av. Miguel Grau'),
        (C, ['Avenida Junín'], 'Av. Junín'),
        (C, ['Avenida Tacna'], 'Av. Tacna'),
        (C, ['Avenida Ramón Castilla', 'Avenida Ramon Castilla'], 'Av. Ramón Castilla'),
        (C, ['Avenida Cayetano Heredia'], 'Av. Cayetano Heredia'),
        (C, ['Avenida Guardia Civil'], 'Av. Guardia Civil'),
        (C, ['Avenida Sánchez Cerro'], 'Av. Sánchez Cerro'),
        (C, ['Avenida Loreto'], 'Av. Loreto'),
        (C, ['Avenida Bolognesi'], 'Av. Bolognesi'),
        (C, ['Avenida San Martín'], 'Av. San Martín'),
        (C, ['Avenida Don Bosco'], 'Av. Don Bosco'),
        (C, ['Calle Buenos Aires', 'Buenos Aires'], 'Calle Buenos Aires'),
        (C, ['Calle Las Américas', 'Calle las Américas'], 'Calle Las Américas'),
        (C, ['Avenida Vía La Legua'], 'Antigua Carretera a La Legua'),
        # Av. Guillermo Gulman: no está en OSM.
        (L, 'Palo Parado'), (L, 'La Piedra'), (L, 'Monte Castillo'),
    ],
    'RD-21': [
        (C, ['Jirón Paita'], 'Jr. Paita'),
        (C, ['Jirón Chulucanas'], 'Jr. Chulucanas'),
        (L, 'Narihualá'),
        (L, 'Catacaos'),
        (L, 'Simbilá'),
        (L, 'La Legua'),
        # Puente Grau y Av. Guillermo Gulman: no están en OSM.
        (P, 'Terminal Satélite (Piura)', -5.20368, -80.64697),
    ],
}


def normalizar(texto):
    sin = unicodedata.normalize('NFD', texto.lower())
    return ''.join(c for c in sin if unicodedata.category(c) != 'Mn')


def dist(a, b):
    lat1, lon1 = map(math.radians, a)
    lat2, lon2 = map(math.radians, b)
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    return 2 * 6371000 * math.asin(min(1, math.sqrt(h)))


# Costo relativo de cada tipo de vía: un bus prefiere avenidas y carreteras.
COSTO_TIPO = {
    'motorway': 0.9, 'trunk': 0.9, 'primary': 1.0, 'secondary': 1.0,
    'tertiary': 1.1, 'unclassified': 1.3, 'residential': 1.3,
    'living_street': 2.0, 'road': 1.5, 'service': 3.0,
}
# Las calles del recorrido oficial cuestan la mitad: el camino las prefiere.
DESCUENTO_OFICIAL = 0.5


class Red:
    """Red vial de OSM: nodos por id, vecinos y nombres de las calles."""

    def __init__(self, elementos):
        self.pos = {}
        self.vecinos = {}
        self.por_nombre = {}
        for w in elementos:
            if w['type'] != 'way' or 'geometry' not in w:
                continue
            nombre = normalizar(w['tags'].get('name', ''))
            costo = COSTO_TIPO.get(w['tags'].get('highway', ''), 1.5)
            ids = w['nodes']
            for nid, g in zip(ids, w['geometry']):
                self.pos[nid] = (g['lat'], g['lon'])
                if nombre:
                    self.por_nombre.setdefault(nombre, set()).add(nid)
            for a, b in zip(ids, ids[1:]):
                d = dist(self.pos[a], self.pos[b])
                self.vecinos.setdefault(a, []).append((b, d, costo, nombre))
                self.vecinos.setdefault(b, []).append((a, d, costo, nombre))

    def nodos_de(self, nombres):
        r = set()
        for n in nombres:
            r |= self.por_nombre.get(normalizar(n), set())
        return r

    def mas_cercano(self, punto, entre=None):
        return min(entre if entre is not None else self.pos,
                   key=lambda n: dist(self.pos[n], punto))

    def camino(self, a, b, oficiales):
        """Camino más corto (A*) de a a b, prefiriendo las calles oficiales."""
        meta = self.pos[b]
        cola = [(0, 0, a)]
        costo = {a: 0}
        previo = {}
        while cola:
            _, c, n = heapq.heappop(cola)
            if n == b:
                break
            if c > costo[n]:
                continue
            for m, d, tipo, nombre in self.vecinos.get(n, []):
                factor = tipo * (DESCUENTO_OFICIAL if nombre in oficiales else 1)
                nc = c + d * factor
                if nc < costo.get(m, float('inf')):
                    costo[m], previo[m] = nc, n
                    heapq.heappush(cola, (nc + dist(self.pos[m], meta) * 0.45, nc, m))
        if b not in costo:
            return None
        ruta, n = [b], b
        while n != a:
            n = previo[n]
            ruta.append(n)
        return [self.pos[x] for x in ruta[::-1]]


def simplificar(puntos, tolerancia):
    """Douglas-Peucker (en metros, aproximado en el plano local)."""
    if len(puntos) < 3:
        return puntos

    def desvio(p, a, b):
        if a == b:
            return dist(p, a)
        lat0 = math.radians(a[0])
        def xy(q):
            return ((q[1] - a[1]) * 111320 * math.cos(lat0), (q[0] - a[0]) * 110540)
        (px, py), (bx, by) = xy(p), xy(b)
        t = max(0, min(1, (px * bx + py * by) / (bx * bx + by * by)))
        return math.hypot(px - t * bx, py - t * by)

    peor, indice = 0, 0
    for i in range(1, len(puntos) - 1):
        d = desvio(puntos[i], puntos[0], puntos[-1])
        if d > peor:
            peor, indice = d, i
    if peor <= tolerancia:
        return [puntos[0], puntos[-1]]
    return simplificar(puntos[:indice + 1], tolerancia)[:-1] + simplificar(puntos[indice:], tolerancia)


def distancia_a_trazado(p, trazado):
    """(metros, posición a lo largo del trazado en metros)."""
    mejor, posicion, acumulado = float('inf'), 0, 0
    for a, b in zip(trazado, trazado[1:]):
        lat0 = math.radians(a[0])
        def xy(q):
            return ((q[1] - a[1]) * 111320 * math.cos(lat0), (q[0] - a[0]) * 110540)
        (px, py), (bx, by) = xy(p), xy(b)
        largo = math.hypot(bx, by)
        t = 0 if largo == 0 else max(0, min(1, (px * bx + py * by) / (largo * largo)))
        d = math.hypot(px - t * bx, py - t * by)
        if d < mejor:
            mejor, posicion = d, acumulado + t * largo
        acumulado += largo
    return mejor, posicion


def largo(trazado):
    return sum(dist(a, b) for a, b in zip(trazado, trazado[1:]))


def punto_de(ancla, red):
    return red.pos[ancla[1]] if ancla[0] == 'nodo' else ancla[1]


def main(f_red, f_pueblos, f_lugares, f_propuestos, salida_json, salida_dart):
    red = Red(json.load(open(f_red))['elements'])
    # Puede haber varios lugares con el mismo nombre (varios "Nuevo
    # Horizonte"): se guarda cada uno y se elige el más cercano al recorrido.
    lugares = {}
    for f in (f_lugares, f_pueblos):
        for e in json.load(open(f))['elements']:
            t = e.get('tags', {})
            if t.get('place') and 'name' in t:
                pos = (e['center']['lat'], e['center']['lon']) if 'center' in e else (e['lat'], e['lon'])
                if pos not in lugares.setdefault(t['name'], []):
                    lugares[t['name']].append(pos)
    propuestos = {r['codigo']: r for r in json.load(open(f_propuestos))['rutas']}
    for codigo in IDS:
        if IDS[codigo] is None:
            IDS[codigo] = propuestos[codigo]['idRuta']

    resultado = {}
    for codigo, recorrido in RECORRIDOS.items():
        oficiales = {normalizar(n) for paso in recorrido if paso[0] == C for n in paso[1]}
        anclas = []      # nodos de la red por los que pasa el bus, en orden
        paraderos = []   # (pos, nombre) de cruces oficiales y lugares
        anterior = None  # (nodos, nombre) de la calle anterior
        for numero, paso in enumerate(recorrido):
            es_destino = numero == len(recorrido) - 1
            if paso[0] in (L, P):
                if paso[0] == P:
                    pos = (paso[2], paso[3])
                else:
                    opciones = lugares.get(paso[1], [])
                    ultimo = punto_de(anclas[-1], red) if anclas else None
                    pos = (min(opciones, key=lambda o: dist(o, ultimo)) if ultimo else opciones[0]) if opciones else None
                if not pos:
                    print(f'  {codigo}: falta el lugar {paso[1]}')
                    continue
                paraderos.append((pos, paso[1]))
                anclas.append(('lugar', pos, paso[1]))
                anterior = None
                continue
            nodos = red.nodos_de(paso[1])
            if not nodos:
                print(f'  {codigo}: falta la calle {paso[2]}')
                continue
            ultimo = punto_de(anclas[-1], red) if anclas else None
            comunes = (anterior[0] & nodos) if anterior else set()
            if comunes:
                nodo = min(comunes, key=lambda n: dist(red.pos[n], ultimo)) if ultimo else next(iter(comunes))
                paraderos.append((red.pos[nodo], f'{anterior[1]} / {paso[2]}'))
                anclas.append(('nodo', nodo, f'{anterior[1]} / {paso[2]}'))
            elif ultimo:
                entrada = red.mas_cercano(ultimo, nodos)
                if dist(red.pos[entrada], ultimo) > CALLE_LEJANA_M and not es_destino:
                    print(f'  {codigo}: {paso[2]} más cercana a '
                          f'{dist(red.pos[entrada], ultimo) / 1000:.1f} km: se omite')
                    continue
                anclas.append(('nodo', entrada, f'entrada a {paso[2]}'))
            anterior = (nodos, paso[2])

        # Trazado: camino por la red entre anclas consecutivas.
        trazado, recto = [], 0
        for a, b in zip(anclas, anclas[1:]):
            pa, pb = punto_de(a, red), punto_de(b, red)
            na = a[1] if a[0] == 'nodo' else red.mas_cercano(pa)
            nb = b[1] if b[0] == 'nodo' else red.mas_cercano(pb)
            tramo = None
            if dist(red.pos[na], pa) < 1500 and dist(red.pos[nb], pb) < 1500:
                tramo = red.camino(na, nb, oficiales)
            if tramo and largo(tramo) < 2.5 * dist(pa, pb) + 1000:
                tramo = ([pa] if a[0] == 'lugar' else []) + tramo + ([pb] if b[0] == 'lugar' else [])
            else:
                tramo = [pa, pb]
                recto += dist(pa, pb)
            trazado += tramo if not trazado else tramo[1:]
            if os.environ.get('DEPURAR') == codigo:
                print(f'    {a[2][:38]:38} -> {b[2][:38]:38} recta {dist(pa, pb):6.0f} m, '
                      f'camino {largo(tramo):6.0f} m')
        trazado = simplificar(trazado, SIMPLIFICA_M)
        total = largo(trazado)
        puntos = [(pos, nombre, None) for pos, nombre in paraderos]

        # Confirmar los paraderos propuestos de la ruta.
        confirmados, descartados = [], []
        for prd in propuestos.get(codigo, {}).get('paraderos', []):
            pos = (prd['latitud'], prd['longitud'])
            d, _ = distancia_a_trazado(pos, trazado)
            (confirmados if d <= CONFIRMA_M else descartados).append((pos, prd['nombre'], round(d)))

        # Paraderos finales: lugares conocidos confirmados y cruces oficiales,
        # en el orden del trazado y sin repetir puntos muy cercanos.
        candidatos = [(pos, nombre, True) for pos, nombre, _ in confirmados]
        candidatos += [(pos, nombre, False) for pos, nombre, _ in puntos]
        ordenados = sorted(candidatos, key=lambda c: distancia_a_trazado(c[0], trazado)[1])
        finales = []
        for pos, nombre, conocido in ordenados:
            igual = next((f for f in finales if dist(f[0], pos) < DUPLICADO_M), None)
            if igual:
                if conocido and not igual[2]:
                    finales[finales.index(igual)] = (pos, nombre, conocido)
                continue
            finales.append((pos, nombre, conocido))

        resultado[codigo] = {
            'idRuta': IDS[codigo],
            'largoKm': round(total / 1000, 1),
            'tramosRectosKm': round(recto / 1000, 1),
            'paraderos': [
                {'nombre': n, 'latitud': round(p[0], 5), 'longitud': round(p[1], 5),
                 'tipo': 'lugar confirmado' if k else 'cruce oficial'}
                for p, n, k in finales
            ],
            'descartados': [{'nombre': n, 'distanciaM': d} for _, n, d in descartados],
            'trazado': [[round(p[0], 5), round(p[1], 5)] for p in trazado],
        }
        print(f'{codigo}: {len(finales)} paraderos ({len(confirmados)} confirmados, '
              f'{len(descartados)} descartados), trazado {total / 1000:.1f} km '
              f'({recto / 1000:.1f} km en línea recta), {len(trazado)} puntos')

    json.dump(resultado, open(salida_json, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    escribir_dart(resultado, salida_dart)


def escribir_dart(resultado, salida):
    def q(s):
        return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"
    lineas = [
        "import 'package:latlong2/latlong.dart';",
        '',
        "import 'models/paradero.dart';",
        '',
        '// Trazados y paraderos de las rutas con recorrido OFICIAL de la',
        '// Municipalidad Provincial de Piura (nota del 7/6/2024). Archivo generado',
        '// por tool/trazados_oficiales.py desde OpenStreetMap (ODbL): no editar a',
        '// mano. Ver docs/datos/rutas-plan-regulador.md.',
        '',
        '/// Recorrido de cada ruta por las calles, por id de ruta.',
        'const trazadosOficiales = <int, List<LatLng>>{',
    ]
    for codigo, r in resultado.items():
        lineas.append(f'  // {codigo}: {r["largoKm"]} km')
        lineas.append(f'  {r["idRuta"]}: [')
        lineas += [f'    LatLng({p[0]}, {p[1]}),' for p in r['trazado']]
        lineas.append('  ],')
    lineas += ['};', '',
               '/// Paraderos en el recorrido oficial: lugares conocidos confirmados',
               '/// (a menos de 200 m del trazado) y cruces de las calles oficiales.',
               'const paraderosOficiales = <int, List<Paradero>>{']
    nid = ID_PARADERO_INICIAL
    for codigo, r in resultado.items():
        lineas.append(f'  // {codigo}')
        lineas.append(f'  {r["idRuta"]}: [')
        for orden, prd in enumerate(r['paraderos'], start=1):
            lineas += ['    Paradero(', f'      idParadero: {nid},', f'      nombre: {q(prd["nombre"])},',
                       f'      latitud: {prd["latitud"]},', f'      longitud: {prd["longitud"]},',
                       f'      ordenSecuencial: {orden},', '    ),']
            nid += 1
        lineas.append('  ],')
    lineas.append('};')
    open(salida, 'w', encoding='utf-8').write('\n'.join(lineas) + '\n')


if __name__ == '__main__':
    main(*sys.argv[1:7])
