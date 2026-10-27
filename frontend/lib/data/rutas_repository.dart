import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import 'models/eta.dart';
import 'models/paradero.dart';
import 'models/resumen_congestion.dart';
import 'models/ruta.dart';
import 'paraderos_propuestos.dart';
import 'trazados_oficiales.dart';

/// Fuente de las rutas. Hoy hay una implementación con datos locales; la
/// versión que llama al backend se agrega después con la misma interfaz.
abstract class RutasRepository {
  Future<List<Ruta>> listar();

  /// Paraderos de una ruta, en orden.
  Future<List<Paradero>> paraderos(int idRuta);

  /// Recorrido de la ruta por las calles (lista de puntos), o vacío si no
  /// se conoce: entonces el mapa une los paraderos en línea recta.
  Future<List<LatLng>> trazado(int idRuta);

  /// Indica que los datos no vienen del backend (sin paraderos reales ni ETA
  /// en vivo): la interfaz lo avisa al usuario.
  bool get esDemostracion;
}

/// Fuente del tiempo de llegada de la próxima unidad. La implementa el
/// repositorio que llama al backend; los datos de prueba no tienen ETA.
abstract class FuenteEta {
  /// ETA de la ruta, o null si el backend no responde.
  Future<Eta?> eta(int idRuta);
}

/// Fuente de la congestión de la ciudad. La implementa el repositorio que
/// llama al backend; los datos de prueba no tienen congestión.
abstract class FuenteCongestion {
  /// Resumen de la franja (MANANA_PICO, MEDIO_DIA, TARDE_PICO o NOCHE) del
  /// día de hoy; sin franja, la de ahora. Null si el backend no responde.
  Future<ResumenCongestion?> resumenCongestion({String? franjaHoraria});

  /// Histórico de congestión en Excel (.xlsx), o null si el backend falla.
  Future<Uint8List?> exportarCongestionExcel();
}

/// Rutas reales de Piura y Castilla tomadas de https://piuratransporta.com/rutas
/// (consultado el 24/10/2026), en el mismo orden: primero las interurbanas
/// (I-), luego las reguladas (RD-) y al final las urbanas (U-). Se suman
/// RD-07, RD-12, RD-13 y RD-17 del Plan Regulador de Rutas (O.M.
/// 092-02-CMPP), que piuratransporta no publica: ver
/// docs/datos/rutas-plan-regulador.md.
///
/// Los paraderos son PROPUESTOS (lugares conocidos con coordenadas de
/// OpenStreetMap, ver paraderos_propuestos.dart) y no hay ETA en vivo: los
/// oficiales llegan del backend al final del proyecto. Copia de los datos en
/// docs/datos/rutas-piuratransporta.json y docs/datos/paraderos-propuestos.json.
class FakeRutasRepository implements RutasRepository {
  const FakeRutasRepository();

  @override
  Future<List<Ruta>> listar() async => _datos;

  /// Si la ruta tiene recorrido oficial de la Municipalidad, sus paraderos
  /// están confirmados sobre ese recorrido (trazados_oficiales.dart); si no,
  /// son los propuestos.
  @override
  Future<List<Paradero>> paraderos(int idRuta) async =>
      paraderosOficiales[idRuta] ??
      paraderosPropuestos[idRuta] ??
      const <Paradero>[];

  @override
  Future<List<LatLng>> trazado(int idRuta) async =>
      trazadosOficiales[idRuta] ?? const <LatLng>[];

  @override
  bool get esDemostracion => true;

  static const _datos = <Ruta>[
    Ruta(
      idRuta: 1,
      codigo: 'I-18',
      nombre: 'Terminal Satélite (Piura) - Terminal La Unión',
      empresa: 'EMTRUBAPI',
      tipoServicio: 'Interurbana',
      puntoInicio: 'Terminal Satélite (Piura)',
      puntoFinal: 'Terminal La Unión',
      frecuenciaMinutos: 10,
      horario: '06:00–21:00',
      pasaje: 3.00,
      pasajeEstudiante: 1.50,
      lugaresDestacados: ['I.E. Nuestra Señora del Carmen'],
    ),
    Ruta(
      idRuta: 2,
      codigo: 'I-19',
      nombre: 'Piura - Catacaos',
      empresa: '6M Buss SAA',
      tipoServicio: 'Interurbana',
      puntoInicio: 'Piura',
      puntoFinal: 'Catacaos',
      frecuenciaMinutos: 15,
      horario: '05:30–22:00',
      pasaje: 3.00,
      pasajeEstudiante: 1.50,
      lugaresDestacados: [
        'I.E. Nuestra Señora de Fatima',
        'Plazuela Merino',
        'Plaza Tres Culturas',
        'Mercado de Castilla',
        'Open Plaza',
        'Univ. Nacional de Piura',
        'Gobierno Regional',
        'Mercado Modelo',
        'Real Plaza',
      ],
    ),
    Ruta(
      idRuta: 3,
      codigo: 'RD-01',
      nombre: 'Ruta Urbana U-09 Guadalupe',
      empresa: 'Guadalupe',
      tipoServicio: 'Urbana',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'I.E. Nuestra Señora de Fatima',
        'Plazuela Merino',
        'I.E. Militar Pedro Ruiz Gallo',
        'Estadio Miguel Grau',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'Mercado Modelo',
        'Real Plaza',
      ],
    ),
    Ruta(
      idRuta: 4,
      codigo: 'RD-02',
      nombre: 'Veintiséis de Octubre - Terela',
      empresa: 'Super Star',
      tipoServicio: 'Regulada',
      puntoInicio: 'Veintiséis de Octubre',
      puntoFinal: 'Terela',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Hospital Santa Rosa',
        'Hospital de Apoyo Santa Rosa',
        'Clínica Oftalmológica Pongo',
        'Establecimiento de Salud I-4 Pachitea',
        'Instituto Médico Soy Diabético',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'Plaza de Armas',
      ],
    ),
    Ruta(
      idRuta: 5,
      codigo: 'RD-03',
      nombre: 'Ruta Urbana U-08 EMUTSA Calle García',
      empresa: 'EMUTSA',
      tipoServicio: 'Regulada',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'I.E. Coar Piura',
        'I.E. Susana Wesley',
        'Carita feliz',
        'Parque Miguel Cortés/Infantil',
        'Plazuela Merino',
        'Univ. Nacional de Piura',
        'Estadio Miguel Grau',
        'Mercado de Castilla',
      ],
    ),
    Ruta(
      idRuta: 6,
      codigo: 'RD-05',
      nombre: 'Parcela J (Piura) - Terminal Las Lomas',
      empresa: 'Rutas del Norte SAC',
      tipoServicio: 'Regulada',
      puntoInicio: 'Parcela J (Piura)',
      puntoFinal: 'Terminal Las Lomas',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Comprende la ruta, en ida de la Parcela J, Av. Sánchez Cerro, Av. Guardia Civil, Km. 21, Alto Grande, Locuto Alto, Ocoto Alto, Hada, Tambogrande, Cruceta, Caserío Partidor, Terminal Las Lomas. De retorno, atravesará el Terminal Terrestre de Las Lomas, Caserío Partidor, Cruceta, Tambogrande, Hada, Ocoto Alto, Locuto Alto, Alto Grande, Km. 21, Av. Guardia Civil, Av. Sánchez Cerro, altura de la Parcela J.',
      frecuenciaMinutos: 30,
      horario: '05:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Parque Néstor Martos Garridos',
        'I.E. Nuestra Señora de Fatima',
        'Plazuela Merino',
        'Catedral de Piura',
        'I.E. Militar Pedro Ruiz Gallo',
        'Estadio Miguel Grau',
        'Mercado Modelo',
        'Real Plaza',
      ],
    ),
    Ruta(
      idRuta: 21,
      codigo: 'RD-07',
      nombre: 'Castilla - Veintiséis de Octubre',
      empresa: '6M Buss SAA',
      tipoServicio: 'Regulada',
      puntoInicio: 'Castilla',
      puntoFinal: 'Veintiséis de Octubre',
      descripcion: 'Recorrido pendiente: solo se conocen los extremos. Fuente: Plan Regulador de Rutas (O.M. 092-02-CMPP), anexo 01. Antes U-10.',
      frecuenciaMinutos: 4,
    ),
    Ruta(
      idRuta: 7,
      codigo: 'RD-08',
      nombre: 'Piura - Catacaos',
      empresa: '6M Buss SAA',
      tipoServicio: 'Regulada',
      puntoInicio: 'Piura',
      puntoFinal: 'Catacaos',
      frecuenciaMinutos: 10,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'I.E. Nuestra Señora de Fatima',
        'Plazuela Merino',
        'Plaza Tres Culturas',
        'Mercado de Castilla',
        'Open Plaza',
        'Gobierno Regional',
        'Mercado Modelo',
        'Real Plaza',
      ],
    ),
    Ruta(
      idRuta: 8,
      codigo: 'RD-09',
      nombre: 'Fundo Vicentenario - Tacala - Miraflores - Los Portales',
      empresa: 'Olas del Pacífico',
      tipoServicio: 'Interurbana',
      frecuenciaMinutos: 4,
      horario: '06:00–22:00',
      pasaje: 3.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'I.E. Militar Pedro Ruiz Gallo',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'I.E. Nuestra Señora de Fatima',
        'Real Plaza',
        'Universidad Cesar Vallejo - UCV',
        'Parque Néstor Martos Garridos',
        'Mercado Modelo',
      ],
    ),
    Ruta(
      idRuta: 9,
      codigo: 'RD-10',
      nombre: 'UPIS San Gabriel Arcángel - Av. Raúl Mata La Cruz',
      empresa: 'Bolognesi 6C SA',
      tipoServicio: 'Regulada',
      puntoInicio: 'UPIS San Gabriel Arcángel',
      puntoFinal: 'Av. Raúl Mata La Cruz',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Su ruta en ida y vuelta, comprende UPIS San Gabriel Arcángel Castilla, Vía Evitamiento Este, Ovalo Evitamiento, Av. Guardia Civil, Vía entre A.H. Nuevo Horizonte, A.H. Valle La Esperanza Etapa 2 y A.H. Ricardo Palma, continúa por Vía entre A.H. Valle La Esperanza-Urb. Cossio del Pomar y A.H. Pecuario Nuevo Horizonte, Vía entre Tacalá y A.H. Virgen de la Paz, Av. Los Jazmines lado de Asociación Pro Vivienda Luis Banchero Ross y Camposanto Parque del Recuerdo Piura, Puente de Miraflores CC, Av. Andrés Avelino Cáceres. Puente: Andrés Avelino Cáceres; Av. Andrés Avelino Cáceres, Av. Sullana, Av. Sánchez Cerro, Av. Loreto, Av. Grau, Richard Cushing, Sáenz Peña, Puerto Rico, Santo Domingo, Av. Guillermo Gulman, prolongación de Calle Yugoslavia entre A.H. Consuelo Gonzales Posada de Velasco y A.H. 31 de Enero, Las Américas, China Popular, Nicaragua y Avenida Raúl Mata La Cruz.',
      frecuenciaMinutos: 20,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Plaza de Armas',
        'Centro de Rehabilitación Profesional Piura',
        'Instituto Médico Soy Diabético',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'I.E. Nuestra Señora de la Paz',
        'Clínica San Miguel II',
        'Clínica San Miguel',
      ],
    ),
    Ruta(
      idRuta: 10,
      codigo: 'RD-11',
      nombre: 'A.H. Los Almendros - Av. José Aguilar Santisteban',
      empresa: 'Santo Toribio de Mogrovejo',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. Los Almendros',
      puntoFinal: 'Av. José Aguilar Santisteban',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Cubrirá la ruta, en ida y vuelta, en la Vía del mercado o Av. Integración (canchas deportivas Cajas Shapaya), y recorrerá la vía del Mercado Zonal San Francisco hasta 4 cuadras antes de llegar a la Av. Guardia Civil, A Av. Los Almendros, Av. Guardia Civil, Av. Cayetano Heredia, Av. Ramón Castilla, Av. Tacna; Puente: Bolognesi; Av. Bolognesi, Av. Sullana, Av. Andrés Avelino Cáceres, Av. D de Ignacio Merino y Av. José Aguilar Santiesteban.',
      frecuenciaMinutos: 25,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'I.E. Militar Pedro Ruiz Gallo',
        'Estadio Miguel Grau',
        'Plaza Tres Culturas',
        'Carita feliz',
        'Parque Miguel Cortés/Infantil',
        'Plaza del Sol (Centro)',
        'Mercado Modelo',
        'Mercado de Castilla',
      ],
    ),
    Ruta(
      idRuta: 22,
      codigo: 'RD-12',
      nombre: 'UPIS Villa Rica - UPIS 11 de Enero',
      empresa: 'Autogas',
      tipoServicio: 'Regulada',
      puntoInicio: 'UPIS Villa Rica',
      puntoFinal: 'UPIS 11 de Enero',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Su ruta, en ida y vuelta, incluirá UPIS Bella Rica, Vía de Evitamiento Este, Proyecto Vivero Sam, Arco de la Asociación Sol y Campo, Asociación de Vivienda El Álamo en Av. Los Jardines, calle Bolognesi, Calle Lalaquiz, Av. Los Almendros, Av. Guardia Civil, Av. Andrés Avelino Cáceres, Av. Independencia. Puente: Eguiguren, Av. Luis A. Eguiguren, Av. Loreto, Prolongación Av. Loreto y Av. Alameda Perú en UPIS 11 de Enero.',
      frecuenciaMinutos: 5,
      lugaresDestacados: [
        'Vía de Evitamiento Este',
        'Av. Los Almendros',
        'Av. Guardia Civil',
        'Av. Andrés A. Cáceres',
        'Av. Independencia',
        'Av. Luis A. Eguiguren',
        'Av. Loreto',
      ],
    ),
    Ruta(
      idRuta: 23,
      codigo: 'RD-13',
      nombre: 'A.H. Los Almendros - Parque Kurt Beer',
      empresa: '3W Tours',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. Los Almendros',
      puntoFinal: 'Parque Kurt Beer',
      descripcion: 'Recorrido pendiente: solo se conocen los extremos. Fuente: Plan Regulador de Rutas (O.M. 092-02-CMPP), anexo 01.',
      frecuenciaMinutos: 5,
    ),
    Ruta(
      idRuta: 11,
      codigo: 'RD-14',
      nombre: 'A.H. El Indio - Curumuy / Ejidos de Huan',
      empresa: 'Nueva Alternativa del Norte',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. El Indio',
      puntoFinal: 'Curumuy / Ejidos de Huan',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Su ruta, en ida y vuelta, contempla la calle 4 El Indio, Av. Sánchez Carrión, Av. Miguel Grau, Av. Junín, Av. Tacna.Puente: Bolognesi; Av. Bolognesi, Av. Loreto, San Cristóbal, San Ramón, Av. Cáceres, Av. Ramón Mujica, Fortunato Chirichigno, Tallanes, PI 984/ Curumuy hasta Casa de Alex. Al retorno, de la Av. Tallanes va a Fortunato Chirichigno, San Ramón y Av. Cáceres.',
      frecuenciaMinutos: 10,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Centro Médico Essalud Castilla',
        'I.E. 14116 San Martin de Porras',
        'I.E. Nuestra Señora del Transito',
        'Aeropuerto de Piura',
        'Plaza de Armas',
        'Establecimiento de Salud I-4 Pachitea',
        'Puesto de Salud Convenio Ejidos de Huan',
        'Univ. de Piura (UDEP)',
      ],
    ),
    Ruta(
      idRuta: 12,
      codigo: 'RD-15',
      nombre: 'Montebello',
      empresa: 'El Piuranito',
      tipoServicio: 'Regulada',
      frecuenciaMinutos: 7,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Real Plaza',
        'Plaza del Sol (Av. Grau-Gulman)',
        'I.E. Nuestra Señora de Fatima',
        'Mercado Modelo',
        'Parque Miguel Cortés/Infantil',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'Univ. de Piura (UDEP)',
      ],
    ),
    Ruta(
      idRuta: 13,
      codigo: 'RD-16',
      nombre: 'A.H. Nuevo Horizonte - Miraflores Country Club',
      empresa: 'Nueva Alternativa',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. Nuevo Horizonte',
      puntoFinal: 'Miraflores Country Club',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Abarcará, en ida y vuelta, la intersección Miraflores Country Club. Recorrerá la vía principal de Boulevard Park, Vía Alameda de los Ficus de urbanización Miraflores Country Club, Puente Miraflores CC., Av. Andrés Avelino Cáceres. Puente: Cáceres; Av. Andrés Avelino Cáceres, Av. Country, Av. Sullana, Av. Víctor Andrés Belaunde, Avenida Vice, Jirón Tambogrande, Tangarará, Jirón Enrique del Villar, Avenida Grau, Avenida Marcavelica hasta Nuevo Horizonte.',
      frecuenciaMinutos: 10,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Establecimiento de Salud I-4 Pachitea',
        'Instituto Médico Soy Diabético',
        'Open Plaza',
        'Centro de Rehabilitación Profesional Piura',
        'I.E. Nuestra Señora de la Paz',
        'Real Plaza',
        'Unidad Médico Legal Piura',
        'Terminal Terrestre',
      ],
    ),
    Ruta(
      idRuta: 24,
      codigo: 'RD-17',
      nombre: 'A.H. Kurt Beer - Las Lomas del Chipe',
      empresa: 'Rápido Universal',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. Kurt Beer',
      puntoFinal: 'Las Lomas del Chipe',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Cubrirá el recorrido, en ida y vuelta, A.H Kurt Beer, Villa Perú Canadá, calle 8 de Octubre, Av. Juan Velasco Alvarado, Av. Raúl Mata La Cruz, Av. Santa Rosa, Av. Bellavista, Av. Grau, Av. Marcavelica, Av. Sánchez Cerro, Av. Vice, Víctor Andrés Belaunde, Jirón B, Av. Sullana, Av. Luis A. Eguiguren, Av. Country, Av. Ramón Mujica, Av. Fortunato Chirichigno, Av. Las Palmeras, Manzanos, Gardenias, Avenida Colectora y la Av. A en Asociación Pro Vivienda Las Lomas del Chipe.',
      frecuenciaMinutos: 6,
      lugaresDestacados: [
        'Villa Perú Canadá',
        'Av. Sánchez Cerro',
        'Av. Sullana',
        'Av. Luis A. Eguiguren',
        'Av. Country',
        'Av. Fortunato Chirichigno',
        'Las Lomas del Chipe',
      ],
    ),
    Ruta(
      idRuta: 14,
      codigo: 'RD-18',
      nombre: 'Granja de Colores',
      empresa: 'Crucero del Norte',
      tipoServicio: 'Regulada',
      activa: false,
      frecuenciaMinutos: 10,
      horario: '06:00–20:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Plaza Tres Culturas',
        'Plaza de Armas',
        'Parque Miguel Cortés/Infantil',
        'Plaza del Sol (Av. Grau-Gulman)',
        'Mercado Modelo',
        'Real Plaza',
        'Terminal Terrestre',
        'Plaza del Sol (Centro)',
      ],
    ),
    Ruta(
      idRuta: 15,
      codigo: 'RD-19',
      nombre: 'A.H. El Indio - Vía Colectora Norte',
      empresa: 'Corredor Morado SAA',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. El Indio',
      puntoFinal: 'Vía Colectora Norte',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Su ruta, en ida y vuelta, involucra la calle C6 de El Indio, Calle C1, Av. Las Flores, Calle Campanitas, Calixto Balarezo, Mariano Melgar, Av. Progreso, Av. Luis Montero, Avenida Andrés Avelino Cáceres. Puente: Cáceres. Avenida Andrés Avelino Cáceres, Av. Country, Av. Luis Eguiguren, Av. Sullana, Av. Cáceres, Jirón Los Incas, Los Diamantes, Avenida Integradora Norte, final de la Vía Colectora.',
      activa: false,
      frecuenciaMinutos: 20,
      horario: '06:00–19:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Establecimiento de Salud I-3 el Indio',
        'Aeropuerto de Piura',
        'Estadio Miguel Grau',
        'Open Plaza',
        'Clínica Bello Horizonte',
        'Real Plaza',
        'Instituto Médico Soy Diabético',
        'I.E. Maria Auxiliadora',
      ],
    ),
    Ruta(
      idRuta: 16,
      codigo: 'RD-20',
      nombre: 'A.H. Chiclayito - CP Monte Castillo',
      empresa: 'Sicán Bus',
      tipoServicio: 'Regulada',
      puntoInicio: 'A.H. Chiclayito',
      puntoFinal: 'CP Monte Castillo',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): Su ruta, en ida, comprende calle Los Andes de Chiclayito, Ignacio Merino, Av. Progreso, Arequipa, Av. Miguel Grau, Av. Junín. Av. Tacna, Ramón Castilla, Av. Cayetano Heredia, Av. Guardia Civil. Puente: Sánchez Cerro. Av. Sánchez Cerro, Av. Loreto, Av. Bolognesi, Av. San Martín, Av. Don Bosco, Buenos Aires, Las Américas, Antigua Carretera a la Legua, Avenida Guillermo Gulman, Mz. H1, 2 cuadras a la izquierda hasta IEP Príncipe de Paz, CP Palo Parado, CP La Piedra y CP Monte Castillo.',
      frecuenciaMinutos: 8,
      horario: '06:00–21:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Plaza del Sol (Av. Grau-Gulman)',
        'Hospital Jorge Reátegui Delgado',
        'Plazuela Merino',
        'Plaza Tres Culturas',
        'Mercado de Castilla',
        'Estadio Miguel Grau',
        'Mercado Modelo',
        'I.E. Nuestra Señora de Fatima',
      ],
    ),
    Ruta(
      idRuta: 17,
      codigo: 'RD-21',
      nombre: 'Cura Mori - Terminal Satélite (Piura)',
      empresa: '6M Buss SAA',
      tipoServicio: 'Regulada',
      puntoInicio: 'Cura Mori',
      puntoFinal: 'Terminal Satélite (Piura)',
      recorrido: 'Recorrido oficial (Municipalidad Provincial de Piura, 7/6/2024): La ruta, en ida y retorno, comprende Cura Mori (Jirón Paita, Loreto, Calle Chulucanas, Avenida Grau), Narihualá PI 1023 Catacaos, carretera Catacaos, cruce Simbila, Puente Grau, cruce La Legua, Av. Guillermo Gulman, Terminal Satélite Sechura (Piura).',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Parque Néstor Martos Garridos',
        'I.E. Nuestra Señora de Fatima',
        'Plaza del Sol (Av. Grau-Gulman)',
        'Hospital Jorge Reátegui Delgado',
        'Parque Miguel Cortés/Infantil',
        'Plazuela Merino',
        'Mercado Modelo',
        'Real Plaza',
      ],
    ),
    Ruta(
      idRuta: 18,
      codigo: 'RD-22',
      nombre: 'III Etapa de Enace - A.H. Cossío del Pomar',
      empresa: 'Urban 3 (U-12)',
      tipoServicio: 'Urbana',
      puntoInicio: 'III Etapa de Enace',
      puntoFinal: 'A.H. Cossío del Pomar',
      frecuenciaMinutos: 20,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Hospital Santa Rosa',
        'I.E. Nuestra Señora de Fatima',
        'Plazuela Merino',
        'I.E. Militar Pedro Ruiz Gallo',
        'Estadio Miguel Grau',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'Mercado Modelo',
      ],
    ),
    Ruta(
      idRuta: 19,
      codigo: 'U-03',
      nombre: 'Urb. Santa Margarita - Centro histórico / Av. Luis A. Eguiguren',
      empresa: 'El Sol de Piura',
      tipoServicio: 'Urbana',
      puntoInicio: 'Urbanización Santa Margarita',
      puntoFinal:
          'Centro histórico / Av. Luis A. Eguiguren (Distrito de Piura)',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Universidad Cesar Vallejo - UCV',
        'Real Plaza',
        'Mercado Modelo',
        'Plazuela Merino',
        'Catedral de Piura',
        'Estadio Miguel Grau',
        'Univ. Nacional de Piura',
        'Open Plaza',
      ],
    ),
    Ruta(
      idRuta: 20,
      codigo: 'U-04',
      nombre: 'Ruta Urbana U-04 El Sol de Piura',
      empresa: 'El Sol de Piura',
      tipoServicio: 'Urbana',
      frecuenciaMinutos: 10,
      horario: '06:00–22:00',
      pasaje: 2.00,
      pasajeEstudiante: 1.00,
      lugaresDestacados: [
        'Plaza del Sol (Av. Grau-Gulman)',
        'Hospital Jorge Reátegui Delgado',
        'Plazuela Merino',
        'Estadio Miguel Grau',
        'Univ. Nacional de Piura',
        'Open Plaza',
        'Mercado Modelo',
        'I.E. Nuestra Señora de Fatima',
      ],
    ),
  ];
}
