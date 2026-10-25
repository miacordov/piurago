# Rutas del Plan Regulador de Rutas de Piura

Las 20 líneas de https://piuratransporta.com/rutas no son todas las de Piura. El **Plan Regulador de Rutas de Transporte Público** de la Municipalidad Provincial de Piura (Ordenanza Municipal **N.° 092-02-CMPP**, del 24/11/2023) tiene **21 rutas diametrales (RD-01 a RD-21)**. Este documento reúne lo que se encontró en fuentes públicas el 25/10/2026 y explica qué se agregó a la app.

## Fuentes

1. **Anexo N.° 01 de la O.M. 092-02-CMPP**, con el resumen de las 21 fichas técnicas. Está reproducido como imagen en la [Resolución de Alcaldía N.° 477-2024-MDT-A](https://cdn.www.gob.pe/uploads/document/file/6566797/5717325-resolucion-de-alcaldia-n-0477-2024-a.pdf) de la Municipalidad Distrital de Tambogrande, página 1, y se transcribió a mano.
2. **Nota oficial de la Municipalidad Provincial de Piura** del 7/6/2024, "[Conoce las nuevas rutas de transporte público en Piura](https://www.gob.pe/institucion/munipiura/noticias/968296-conoce-las-nuevas-rutas-de-transporte-publico-en-piura-que-facilitaran-el-desplazamientos-de-las-familias-piuranas)". Tiene el recorrido calle por calle de RD-05, RD-10, RD-11, RD-12, RD-14, RD-16, RD-17, RD-19, RD-20 y RD-21.
3. **[El Tiempo, 31/1/2025](https://eltiempo.pe/local/municipalidad-de-piura-autoriza-cuatro-nuevos-recorridos-del-plan-regulador-de-rutas/)**: RD-09 (Olas del Pacífico), RD-13 (3W Tours), RD-15 (El Piuranito) y RD-18 (Crucero del Norte).
4. **[Wikipedia: Directorio de rutas de transporte público de Piura Metropolitana](https://es.wikipedia.org/wiki/Anexo:Directorio_de_rutas_de_transporte_p%C3%BAblico_de_Piura_Metropolitana)**: 28 rutas con su código antiguo. Está marcada como **desactualizada** desde el 10/4/2025.

## Anexo N.° 01: las 21 rutas del plan

Transcripción a mano de una imagen escaneada. Algunos dígitos pueden tener errores de lectura. Las frecuencias son los intervalos entre buses previstos por el plan, en minutos.

| Ruta (código antiguo) | Frecuencia (min) | Longitud (km) | Flota requerida |
|---|---|---|---|
| RD-01 (U-09) | 4 – 5 | 16.8 | 33 |
| RD-02 (U-06) | 2.5 – 3 | 12.9 | 41 |
| RD-03 (U-08) | 4 – 5 | 18.4 | 35 |
| RD-04 (U-04) | 3.5 – 5 | 15.3 | 35 |
| RD-05 (I-15) | 15 – 15 | 96.2 | 28 |
| RD-06 (I-18) | 2.5 – 4 | 29.7 | 55 |
| RD-07 (U-10) | 3.5 – 4 | 22.0 | 30 |
| RD-08 (I-19) | 2.5 – 4 | 18.3 | 36 |
| RD-09 | 4 – 6 | 17.3 | 34 |
| RD-10 | 5 – 6 | 20.8 | 32 |
| RD-11 | 4 – 5 | 14.8 | 29 |
| RD-12 | 4 – 5 | 11.3 | 23 |
| RD-13 | 4 – 5 | 13.7 | 27 |
| RD-14 | 4 – 8 | 14.9 | 29 |
| RD-15 | 4 – 8 | 32.7 | 60 |
| RD-16 | 5 – 8 | 11.8 | 19 |
| RD-17 | 4 – 6 | 14.6 | 29 |
| RD-18 | 4 – 6 | 11.2 | 23 |
| RD-19 | 4 – 6 | 13.3 | 27 |
| RD-20 | 4 – 6 | 15.8 | 31 |
| RD-21 | 4 – 6 | 18.9 | 36 |
| **Total** | | **440.7** | **692** |

## Qué se agregó a la app

piuratransporta ya tiene casi todas: algunas con el código del plan (RD-01, RD-02, RD-03, RD-05, RD-08…) y otras con el antiguo (I-18 = RD-06, U-04 = RD-04). Faltaban **cuatro**:

| Línea | Empresa | Extremos | Recorrido | Paraderos |
|---|---|---|---|---|
| **RD-07** (antes U-10) | 6M Buss SAA | Castilla – Veintiséis de Octubre | Pendiente | Ninguno |
| **RD-12** | Autogas | UPIS Villa Rica – UPIS 11 de Enero | Oficial (nota del 7/6/2024) | 8 propuestos |
| **RD-13** | 3W Tours | A.H. Los Almendros – Parque Kurt Beer | Pendiente | Ninguno |
| **RD-17** | Rápido Universal | A.H. Kurt Beer – Las Lomas del Chipe | Oficial (nota del 7/6/2024) | 10 propuestos |

- **Frecuencia:** el mayor de los dos intervalos del anexo, el más conservador. No hay horario ni pasaje publicados.
- **Líneas sin recorrido:** las que no tienen recorrido publicado (RD-07, RD-13) dicen "Recorrido pendiente" y no tienen paraderos. Salen en la lista de Rutas, pero no en "¿A dónde vas?".

Los paraderos y el trazado de RD-12 y RD-17 se calculan como los del resto de rutas con recorrido oficial: ver la sección siguiente.

## Trazados y paraderos confirmados con el recorrido oficial

Las 10 rutas con recorrido calle por calle en la nota de la Municipalidad (RD-05, RD-10, RD-11, RD-12, RD-14, RD-16, RD-17, RD-19, RD-20 y RD-21) tienen ahora un **trazado por las calles** y **paraderos confirmados**. Lo calcula `frontend/tool/trazados_oficiales.py`, con la red vial de OpenStreetMap (© colaboradores de OpenStreetMap, ODbL). El resultado está en `trazados-oficiales.json` y la app lo usa desde `frontend/lib/data/trazados_oficiales.dart`.

### Cómo se calcula

1. **Recorrido oficial en orden.** Se siguen las calles oficiales en el orden de la nota. Donde una calle cruza a la siguiente (nodo compartido en OpenStreetMap) va un paradero. Si no se cruzan, se entra a la calle por su punto más cercano.
2. **Homónimos.** Si una calle o un lugar tiene varios homónimos (varios "Nuevo Horizonte", varias "Av. Ignacio Merino"), se usa el más cercano al punto anterior. Si el más cercano queda a más de 2.5 km, se omite porque es otra calle con el mismo nombre (salvo el destino final).
3. **Trazado.** Los puntos se unen por la **red vial real** (camino más corto), prefiriendo las calles oficiales de la ruta. El trazado sigue calles de punta a punta. Solo es línea recta donde la red descargada no llega: los tramos rurales de la RD-05 hacia Tambogrande y Las Lomas.
4. **Confirmación.** Los paraderos propuestos que ya tenía la ruta se **confirman** si quedan a 200 m o menos del trazado oficial; los demás se **descartan**. Los paraderos finales son los lugares confirmados más los cruces oficiales, en el orden del trazado.

### Resultado

| Ruta | Trazado (km) | Longitud oficial (km) | En línea recta (km) | Paraderos | Paraderos propuestos descartados (distancia al recorrido) |
|---|---|---|---|---|---|
| RD-05 | 100.0 | 96.2 | 21.2 | 10 (2 lugares confirmados) | Parque Néstor Martos Garridos (2345 m), Real Plaza (2300 m), I.E. Nuestra Señora de Fatima (1580 m), Mercado Modelo (1303 m), Plazuela Merino (254 m), Catedral de Piura (483 m) |
| RD-10 | 19.6 | 20.8 | 0.0 | 10 (6 lugares confirmados) | Univ. Nacional de Piura (622 m), Plaza de Armas (399 m) |
| RD-11 | 9.8 | 14.8 | 0.0 | 13 (7 lugares confirmados) | Plaza Tres Culturas (240 m), Plaza del Sol (Centro) (222 m) |
| RD-12 | 7.8 | 11.3 | 0.0 | 8 | — |
| RD-14 | 15.5 | 14.9 | 0.0 | 11 (5 lugares confirmados) | I.E. Nuestra Señora del Transito (340 m), Aeropuerto de Piura (727 m), Plaza de Armas (362 m), Establecimiento de Salud I-4 Pachitea (455 m), Univ. de Piura (UDEP) (1206 m) |
| RD-16 | 15.6 | 11.8 | 0.0 | 10 (6 lugares confirmados) | Terminal Terrestre (421 m), Establecimiento de Salud I-4 Pachitea (214 m), Unidad Médico Legal Piura (328 m), Miraflores Country Club (1279 m) |
| RD-17 | 16.2 | 14.6 | 0.0 | 12 | — |
| RD-19 | 17.3 | 13.3 | 0.0 | 13 (6 lugares confirmados) | Aeropuerto de Piura (758 m), Real Plaza (299 m), Clínica Bello Horizonte (376 m) |
| RD-20 | 29.1 | 15.8 | 0.0 | 16 (5 lugares confirmados) | Plaza Tres Culturas (240 m), Estadio Miguel Grau (384 m), Mercado Modelo (683 m), I.E. Nuestra Señora de Fatima (502 m), Hospital Jorge Reátegui Delgado (358 m) |
| RD-21 | 17.1 | 18.9 | 0.0 | 5 (1 lugar confirmado) | Parque Néstor Martos Garridos (1551 m), Plaza del Sol (Av. Grau-Gulman) (1486 m), Hospital Jorge Reátegui Delgado (1653 m), I.E. Nuestra Señora de Fatima (1913 m), Mercado Modelo (2208 m), Parque Miguel Cortés/Infantil (1882 m), Plazuela Merino (2633 m), Real Plaza (2170 m) |

**Cómo leer la tabla:**
- **Longitud:** la del trazado coincide con la oficial en RD-05, RD-10, RD-14, RD-17, RD-19 y RD-21.
- **RD-11 y RD-12 quedan más cortas:** sus extremos ("Vía del Mercado Zonal San Francisco", "UPIS Villa Rica", "UPIS 11 de Enero") no están en OpenStreetMap.
- **RD-16 y RD-20 quedan más largas.** La RD-20 sola, desde Las Américas hasta Monte Castillo por carretera, ya mide unos 15 km, así que la longitud oficial podría no cubrir todo el recorrido. **Por verificar con la ficha técnica.**
- **Descartados:** los lugares que piuratransporta dice que la ruta "pasa por", pero que quedan lejos del recorrido oficial de la Municipalidad.

### Calles del recorrido oficial que no están en OpenStreetMap

- Parcela J, Hada (RD-05)
- Av. Guillermo Gulman y Av. Raúl Mata La Cruz (RD-10, RD-20, RD-21)
- Puente Grau (RD-21)
- Jr. Enrique del Villar (RD-16)
- Av. Ramón Mujica (RD-14, RD-17)
- Vía del Mercado Zonal San Francisco (RD-11)
- UPIS Villa Rica y UPIS 11 de Enero (RD-12)
- Calle 8 de Octubre (RD-17)

## Diferencias entre fuentes (por verificar)

| Tema | piuratransporta | Otra fuente |
|---|---|---|
| Empresa de RD-11 | Lugueda | Santo Toribio de Mogrovejo SAC (nota de la Municipalidad y Wikipedia). **La app usa el dato de la Municipalidad.** |
| Empresa de RD-14 | Nueva Alternativa | Nueva Alternativa del Norte SAC (Municipalidad). **La app usa el dato de la Municipalidad.** |
| Recorrido de RD-21 | Piura – Catacaos | Cura Mori – Terminal Satélite (Piura), pasando por Catacaos (Municipalidad). **La app usa el dato de la Municipalidad.** |
| Estado de U-03 | Activa (El Sol de Piura) | Inactiva (Wikipedia) |
| RD-13 | — | Adjudicada a 3W Tours (El Tiempo, 2025); antes se reportó desierta |

**Rutas antiguas en Wikipedia** que no se agregaron, porque no tienen recorrido, pueden estar repetidas con otro código y la página está desactualizada:
- **Activas:** U-01 (Conetrans, Piura – Castilla), U-11 (TransPiura, Piura – Castilla), I-13 (TransPiura, Los Ejidos del Norte – La Legua) e I-16 (Pueblos Unidos por Jesús, Veintiséis de Octubre – El Tabanco).
- **Inactivas:** U-02, U-07 e I-17.
- **Desiertas:** U-05 e I-14.

## Para tener los datos completos

Faltan las **fichas técnicas** del plan: recorrido, paraderos y planos de cada ruta. Ver `solicitud-fichas-tecnicas.md` para pedirlas a la Municipalidad.
