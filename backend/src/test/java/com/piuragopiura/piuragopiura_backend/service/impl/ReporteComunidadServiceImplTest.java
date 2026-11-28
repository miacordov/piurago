package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.ReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.TipoReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.ReporteComunidadRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReporteComunidadServiceImplTest {

    @Mock private ReporteComunidadRepository reporteComunidadRepository;
    @Mock private UsuarioRepository usuarioRepository;
    @Mock private RutaRepository rutaRepository;

    private ReporteComunidadServiceImpl service;

    private final Usuario usuario = new UsuarioAnonimo();

    @BeforeEach
    void setUp() {
        service = new ReporteComunidadServiceImpl(reporteComunidadRepository, usuarioRepository, rutaRepository);
    }

    private void guardaLoQueRecibe() {
        when(reporteComunidadRepository.save(any(ReporteComunidad.class)))
                .thenAnswer(invocacion -> invocacion.getArgument(0));
    }

    @Test
    void guardaUnReportePendienteConLaRutaYLaUbicacion() {
        Ruta ruta = new Ruta();
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(rutaRepository.findById(7L)).thenReturn(Optional.of(ruta));
        guardaLoQueRecibe();

        ReporteComunidad reporte = service.registrar(1L, TipoReporteComunidad.RUTA_CAMBIO, 7L,
                "  Ya no entra por la Av. Grau  ", new BigDecimal("-5.19"), new BigDecimal("-80.63"));

        assertThat(reporte.getUsuario()).isSameAs(usuario);
        assertThat(reporte.getRuta()).isSameAs(ruta);
        assertThat(reporte.getTipo()).isEqualTo(TipoReporteComunidad.RUTA_CAMBIO);
        assertThat(reporte.getDescripcion()).isEqualTo("Ya no entra por la Av. Grau");
        assertThat(reporte.getLatitud()).isEqualByComparingTo("-5.19");
        assertThat(reporte.getLongitud()).isEqualByComparingTo("-80.63");
        assertThat(reporte.getEstado()).isEqualTo("PENDIENTE");
        assertThat(reporte.getFechaHora()).isNotNull();
    }

    @Test
    void laRutaYLaUbicacionSonOpcionales() {
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        guardaLoQueRecibe();

        ReporteComunidad reporte = service.registrar(1L, TipoReporteComunidad.OTRO, null,
                "Hay un paradero nuevo frente al mercado", null, null);

        assertThat(reporte.getRuta()).isNull();
        assertThat(reporte.getLatitud()).isNull();
        assertThat(reporte.getLongitud()).isNull();
        verifyNoInteractions(rutaRepository);
    }

    @Test
    void rechazaUnaDescripcionVaciaSinTocarLaBaseDeDatos() {
        assertThatThrownBy(() -> service.registrar(1L, TipoReporteComunidad.OTRO, null, "   ", null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Describe");

        verifyNoInteractions(reporteComunidadRepository, usuarioRepository, rutaRepository);
    }

    @Test
    void rechazaUnaDescripcionDeMasDe500Caracteres() {
        String larga = "a".repeat(501);

        assertThatThrownBy(() -> service.registrar(1L, TipoReporteComunidad.OTRO, null, larga, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("500");

        verifyNoInteractions(reporteComunidadRepository);
    }

    @Test
    void rechazaUnaUbicacionIncompleta() {
        assertThatThrownBy(() -> service.registrar(1L, TipoReporteComunidad.PARADERO_NUEVO, null,
                "Paradero nuevo", new BigDecimal("-5.19"), null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("latitud y longitud");

        verifyNoInteractions(reporteComunidadRepository);
    }

    @Test
    void rechazaUnaUbicacionFueraDePeru() {
        assertThatThrownBy(() -> service.registrar(1L, TipoReporteComunidad.PARADERO_NUEVO, null,
                "Paradero nuevo", new BigDecimal("10.0"), new BigDecimal("-80.0")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Latitud fuera de rango");

        verifyNoInteractions(reporteComunidadRepository);
    }

    @Test
    void rechazaUnTipoNulo() {
        assertThatThrownBy(() -> service.registrar(1L, null, null, "Algo", null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("tipo");

        verifyNoInteractions(reporteComunidadRepository);
    }

    @Test
    void rechazaUnaRutaQueNoExiste() {
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(rutaRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.registrar(1L, TipoReporteComunidad.RUTA_CAMBIO, 99L,
                "Cambió el recorrido", null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ruta no encontrada");

        verifyNoInteractions(reporteComunidadRepository);
    }
}
