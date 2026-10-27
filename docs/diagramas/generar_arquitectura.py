"""Genera docs/diagramas/arquitectura-capas.svg: diagrama de capas del backend.

Uso: python3 docs/diagramas/generar_arquitectura.py docs/diagramas/arquitectura-capas.svg
Si cambian las clases del backend, actualizar las listas de este script.
"""
import sys
from html import escape

salida = sys.argv[1]
W, H = 1500, 1120
MX0, MX1 = 40, 1150          # columna principal
SX0, SX1 = 1180, 1460        # columna lateral

C = dict(texto='#121B2D', suave='#5D6A78', borde='#CEDDEB', fondo='#FFFFFF', pagina='#F5F8FC',
         primario='#342EC1', primarioSuave='#E6E9FB', verde='#0B7A3E', verdeSuave='#E3F3EA',
         naranja='#A8650F', naranjaSuave='#FBF0DF', gris='#EEF2F7', rojo='#C62828')

out = []
def add(s): out.append(s)

def rect(x, y, w, h, fill, stroke, r=8, dash=None, sw=1.2):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>')

def text(x, y, s, size=13, weight=400, color=None, anchor='middle', italic=False):
    st = ' font-style="italic"' if italic else ''
    add(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{color or C["texto"]}" '
        f'text-anchor="{anchor}"{st}>{escape(s)}</text>')

def flecha(x1, y1, x2, y2, color=None, dash=None, sw=1.6, marca='flecha'):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color or C["suave"]}" stroke-width="{sw}"{d} '
        f'marker-end="url(#{marca})"/>')

def capa(y, h, titulo, subtitulo, fill, stroke):
    rect(MX0, y, MX1 - MX0, h, fill, stroke, r=12)
    text(MX0 + 16, y + 24, titulo, 14, 700, stroke, 'start')
    text(MX0 + 16, y + 42, subtitulo, 12, 400, C['suave'], 'start')

def cajas(y, nombres, fill, stroke, h=44, etiqueta=None, x0=MX0 + 16, x1=MX1 - 16, gap=12, size=12.5):
    n = len(nombres)
    w = (x1 - x0 - gap * (n - 1)) / n
    centros = []
    for i, nombre in enumerate(nombres):
        x = x0 + i * (w + gap)
        rect(x, y, w, h, fill, stroke, r=6)
        tam = min(size, (w - 10) / (len(nombre) * 0.6))
        partes = [nombre]
        if tam < 10.5 and 'Congestion' in nombre:
            # Nombre largo: en dos líneas, cortando después de "...Congestion".
            corte = nombre.index('Congestion') + len('Congestion')
            partes = [nombre[:corte], nombre[corte:]]
            tam = min(size, (w - 10) / (max(len(t) for t in partes) * 0.6))
        y0 = y + (24 if etiqueta else 0)
        alto = h - (24 if etiqueta else 0)
        if etiqueta:
            text(x + w / 2, y + 16, etiqueta, 10.5, 400, C['suave'], italic=True)
        if len(partes) == 1:
            text(x + w / 2, y0 + alto / 2 + 5 - (4 if etiqueta else 0), nombre, tam, 600)
        else:
            text(x + w / 2, y0 + alto / 2 - 2 - (4 if etiqueta else 0), partes[0], tam, 600)
            text(x + w / 2, y0 + alto / 2 + 12 - (4 if etiqueta else 0), partes[1], tam, 600)
        centros.append((x, w))
    return centros

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
    f'font-family="Inter, Roboto, Segoe UI, Arial, sans-serif">')
add('<defs>'
    f'<marker id="flecha" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{C["suave"]}"/></marker>'
    f'<marker id="flechaRoja" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{C["rojo"]}"/></marker>'
    f'<marker id="hereda" viewBox="0 0 12 12" refX="11" refY="6" markerWidth="10" markerHeight="10" orient="auto-start-reverse"><path d="M0,0 L11,6 L0,12 z" fill="#fff" stroke="{C["suave"]}"/></marker>'
    '</defs>')
add(f'<rect width="{W}" height="{H}" fill="{C["pagina"]}"/>')

text(MX0, 38, 'PiuraGo — Arquitectura del backend por capas (MVC + DAO)', 22, 700, anchor='start')
text(MX0, 60, 'Spring Boot 4 · Java 21 · generado desde los imports del código (backend/src/main/java)', 13, 400, C['suave'], 'start')

# Cliente
rect(MX0 + 300, 80, 510, 46, C['fondo'], C['primario'], r=23, sw=1.6)
text(MX0 + 555, 108, 'App PiuraGo (Flutter · web y Android)', 14, 700, C['primario'])
flecha(MX0 + 555, 126, MX0 + 555, 156)
text(MX0 + 565, 146, 'HTTP + JSON · Authorization: Bearer <JWT>', 12, 400, C['suave'], 'start')

# Seguridad
rect(MX0, 160, MX1 - MX0, 52, C['gris'], C['suave'], r=10, dash='6 4')
text(MX0 + 16, 182, 'SEGURIDAD (transversal, Spring Security)', 13, 700, C['suave'], 'start')
text(MX0 + 16, 201, 'JwtAuthFilter → JwtUtil · CustomUserDetailsService · SecurityConfig (roles, BCrypt, CORS)'
     ' · GlobalExceptionHandler', 12, 400, C['suave'], 'start')
flecha(MX0 + 555, 212, MX0 + 555, 236)

# Controller
yC = 240
capa(yC, 112, 'CONTROLLER  (C de MVC)', 'Recibe la petición, valida y responde con DTO. Depende solo de interfaces de service.',
     C['primarioSuave'], C['primario'])
ctrl = cajas(yC + 54, ['AuthController', 'UsuarioController', 'RutaController', 'ReporteGpsController',
                       'HistoricoCongestionController'], C['fondo'], C['primario'], size=12)
flecha(MX0 + 555, yC + 112, MX0 + 555, yC + 148)
text(MX0 + 565, yC + 136, 'inyección por constructor de interfaces (D de SOLID)', 12, 400, C['suave'], 'start')

# Service
yS = 392
capa(yS, 196, 'SERVICE  (lógica de negocio)', 'Una interfaz por área (I de SOLID) y su implementación *ServiceImpl (S de SOLID).',
     C['verdeSuave'], C['verde'])
servicios = ['UsuarioService', 'RutaService', 'ReporteGpsService', 'EtaService', 'HistoricoCongestionService',
             'ExportacionCongestionService']
interf = cajas(yS + 52, servicios, C['fondo'], C['verde'], h=54, etiqueta='«interface»', size=11.5, gap=10)
impls = cajas(yS + 130, [s + 'Impl' for s in servicios], C['fondo'], C['verde'], h=42, size=11, gap=10)
for (x, w) in interf:
    flecha(x + w / 2, yS + 130, x + w / 2, yS + 107, dash='5 3', marca='hereda', sw=1.2)
text(MX1 - 16, yS + 186, 'Ayuda compartida: FranjaHoraria (franja y día de una hora)', 11.5, 400, C['suave'], 'end')
flecha(MX0 + 555, yS + 196, MX0 + 555, yS + 232)
text(MX0 + 565, yS + 220, 'usa (acceso a datos solo por repositorios)', 12, 400, C['suave'], 'start')

# Repository
yR = 628
capa(yR, 112, 'REPOSITORY  (patrón DAO)', 'Spring Data JPA: encapsula el acceso a la base.',
     C['naranjaSuave'], C['naranja'])
repos = cajas(yR + 54, ['UsuarioRepository', 'UsuarioAnonimoRepo.', 'UsuarioRegistradoRepo.', 'RutaRepository',
                        'ParaderoRepository', 'ReporteGpsRepository', 'HistoricoCongestionRepository'],
              C['fondo'], C['naranja'], etiqueta='«JpaRepository»', size=11, gap=8)
flecha(MX0 + 555, yR + 112, MX0 + 555, yR + 148)
text(MX0 + 565, yR + 136, 'mapea (JPA / Hibernate)', 12, 400, C['suave'], 'start')

# Model
yM = 780
capa(yM, 150, 'MODEL  (M de MVC)', 'Entidades JPA. Los DTO van aparte: las entidades no salen de la API.',
     C['gris'], C['texto'])
mod = cajas(yM + 54, ['Usuario  «abstracta»', 'Ruta', 'Paradero', 'ReporteGps', 'HistoricoCongestion'],
            C['fondo'], C['texto'], size=12)
ux, uw = mod[0]
subs = cajas(yM + 110, ['UsuarioAnonimo', 'UsuarioRegistrado'], C['fondo'], C['texto'], h=30,
             x0=MX0 + 16, x1=MX0 + 16 + 2 * uw + 12, gap=12, size=11)
yBus = yM + 104
for (x, w) in subs:
    add(f'<line x1="{x + w / 2}" y1="{yM + 110}" x2="{x + w / 2}" y2="{yBus}" stroke="{C["suave"]}" stroke-width="1.2"/>')
add(f'<line x1="{subs[0][0] + subs[0][1] / 2}" y1="{yBus}" x2="{subs[1][0] + subs[1][1] / 2}" y2="{yBus}" '
    f'stroke="{C["suave"]}" stroke-width="1.2"/>')
flecha(ux + uw / 2, yBus, ux + uw / 2, yM + 99, marca='hereda', sw=1.2)
text(MX0 + 16 + 2 * uw + 24, yM + 130, 'herencia JOINED: se usan donde se espera un Usuario (L de SOLID)',
     11.5, 400, C['suave'], 'start')
flecha(MX0 + 555, yM + 150, MX0 + 555, yM + 184)

# Base de datos
add(f'<ellipse cx="{MX0 + 555}" cy="{yM + 196}" rx="200" ry="12" fill="{C["fondo"]}" stroke="{C["texto"]}"/>')
rect(MX0 + 355, yM + 196, 400, 52, C['fondo'], C['texto'], r=0)
add(f'<path d="M{MX0 + 355},{yM + 248} a200,12 0 0,0 400,0" fill="{C["fondo"]}" stroke="{C["texto"]}"/>')
add(f'<rect x="{MX0 + 356}" y="{yM + 197}" width="398" height="50" fill="{C["fondo"]}"/>')
add(f'<ellipse cx="{MX0 + 555}" cy="{yM + 196}" rx="200" ry="12" fill="{C["gris"]}" stroke="{C["texto"]}"/>')
text(MX0 + 555, yM + 232, 'PostgreSQL (Neon)', 14, 700)

text(MX1 - 16, yR + 24, 'Ningún controller los usa. Solo usan clases de model.', 12, 400, C['suave'], 'end')

# Columna lateral
def panel(y, h, titulo, lineas, stroke, fill=C['fondo'], size=11.5):
    rect(SX0, y, SX1 - SX0, h, fill, stroke, r=10)
    text(SX0 + 14, y + 22, titulo, 13, 700, stroke, 'start')
    for i, l in enumerate(lineas):
        text(SX0 + 14, y + 44 + i * 18, l, size, 400, C['texto'], 'start')

panel(240, 250, 'DTO  (V de MVC en la API)', [
    'Entrada: LoginRequestDTO,', 'RegistroRequestDTO, AnonimoRequestDTO,', 'ReporteGpsRequestDTO',
    'Salida: AuthResponseDTO,', 'AnonimoResponseDTO, RutaResponseDTO,', 'ParaderoResponseDTO,',
    'ReporteGpsResponseDTO, EtaResponseDTO,', 'HistoricoCongestionResponseDTO,', 'ResumenCongestionDTO',
    'La vista gráfica es la app Flutter.'], C['primario'])
panel(506, 86, 'TAREA PROGRAMADA', ['RecalculoCongestionProgramado', '@Scheduled cada hora →',
                                     'HistoricoCongestionService'], C['verde'])
panel(608, 196, 'LIBRERÍAS JAVA', [
    'Guava: caché del ETA (10 s)', '   en CacheConfig', 'Apache Commons Lang3: Range', '   en ReporteGpsServiceImpl',
    'Apache POI: Excel (.xlsx) en', '   ExportacionCongestionServiceImpl', 'Logback: logback-spring.xml',
    'jjwt (JWT) · springdoc (Swagger)'], C['naranja'])
panel(816, 116, 'LEYENDA', [], C['suave'])
flecha(SX0 + 16, 868, SX0 + 60, 868); text(SX0 + 70, 872, 'usa / depende de', 11.5, anchor='start')
flecha(SX0 + 16, 892, SX0 + 60, 892, dash='5 3', marca='hereda', sw=1.2); text(SX0 + 70, 896, 'implementa / hereda', 11.5, anchor='start')
text(SX0 + 14, 920, 'Pruebas: Mockito sobre las interfaces', 11, 400, C['suave'], 'start')

add('</svg>')
open(salida, 'w', encoding='utf-8').write('\n'.join(out))
