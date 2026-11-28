package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.ReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.TipoReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.repository.ReporteComunidadRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRepository;
import com.piuragopiura.piuragopiura_backend.service.ReporteComunidadService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class ReporteComunidadServiceImpl implements ReporteComunidadService {

    static final int MAX_DESCRIPCION = 500;

    private final ReporteComunidadRepository reporteComunidadRepository;
    private final UsuarioRepository usuarioRepository;
    private final RutaRepository rutaRepository;

    public ReporteComunidadServiceImpl(ReporteComunidadRepository reporteComunidadRepository,
                                       UsuarioRepository usuarioRepository,
                                       RutaRepository rutaRepository) {
        this.reporteComunidadRepository = reporteComunidadRepository;
        this.usuarioRepository = usuarioRepository;
        this.rutaRepository = rutaRepository;
    }

    @Override
    public ReporteComunidad registrar(Long idUsuario, TipoReporteComunidad tipo, Long idRuta,
                                      String descripcion, BigDecimal latitud, BigDecimal longitud) {
        if (tipo == null) {
            throw new IllegalArgumentException("Indica el tipo de reporte");
        }
        String texto = descripcion == null ? "" : descripcion.strip();
        if (texto.isEmpty()) {
            throw new IllegalArgumentException("Describe qué cambió");
        }
        if (texto.length() > MAX_DESCRIPCION) {
            throw new IllegalArgumentException("La descripción admite hasta " + MAX_DESCRIPCION + " caracteres");
        }
        if ((latitud == null) != (longitud == null)) {
            throw new IllegalArgumentException("La ubicación necesita latitud y longitud");
        }
        if (latitud != null) {
            CoordenadasPeru.validar(latitud, longitud);
        }

        Usuario usuario = usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado: " + idUsuario));
        Ruta ruta = idRuta == null ? null : rutaRepository.findById(idRuta)
                .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada: " + idRuta));

        ReporteComunidad reporte = new ReporteComunidad();
        reporte.setUsuario(usuario);
        reporte.setRuta(ruta);
        reporte.setTipo(tipo);
        reporte.setDescripcion(texto);
        reporte.setLatitud(latitud);
        reporte.setLongitud(longitud);
        return reporteComunidadRepository.save(reporte);
    }
}
