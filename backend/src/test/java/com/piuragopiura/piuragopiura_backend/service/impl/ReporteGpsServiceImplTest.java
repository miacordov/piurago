package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReporteGpsServiceImplTest {

    @Mock private ReporteGpsRepository reporteGpsRepository;
    @Mock private UsuarioRepository usuarioRepository;
    @Mock private RutaRepository rutaRepository;

    private ReporteGpsServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new ReporteGpsServiceImpl(reporteGpsRepository, usuarioRepository, rutaRepository);
    }

    @Test
    void rechazaUnaLatitudFueraDePeruSinTocarLaBaseDeDatos() {
        assertThatThrownBy(() -> service.registrarReporte(1L, 2L, new BigDecimal("10.0"), new BigDecimal("-80.0")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Latitud fuera de rango");

        verifyNoInteractions(reporteGpsRepository, usuarioRepository, rutaRepository);
    }

    @Test
    void rechazaUnaLongitudFueraDePeruSinTocarLaBaseDeDatos() {
        assertThatThrownBy(() -> service.registrarReporte(1L, 2L, new BigDecimal("-5.0"), new BigDecimal("-10.0")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Longitud fuera de rango");

        verifyNoInteractions(reporteGpsRepository, usuarioRepository, rutaRepository);
    }

    @Test
    void rechazaUnUsuarioInexistente() {
        when(usuarioRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.registrarReporte(1L, 2L, new BigDecimal("-5.19"), new BigDecimal("-80.63")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Usuario no encontrado");

        verify(reporteGpsRepository, never()).save(any());
        verifyNoInteractions(rutaRepository);
    }

    @Test
    void rechazaUnaRutaInexistente() {
        Usuario usuario = new UsuarioAnonimo();
        usuario.setIdUsuario(1L);
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(rutaRepository.findById(2L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.registrarReporte(1L, 2L, new BigDecimal("-5.19"), new BigDecimal("-80.63")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ruta no encontrada");

        verify(reporteGpsRepository, never()).save(any());
    }

    @Test
    void registraElReporteConUsuarioRutaYCoordenadas() {
        Usuario usuario = new UsuarioAnonimo();
        usuario.setIdUsuario(1L);
        Ruta ruta = new Ruta();
        ruta.setIdRuta(2L);

        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(rutaRepository.findById(2L)).thenReturn(Optional.of(ruta));
        when(reporteGpsRepository.save(any(ReporteGps.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReporteGps guardado = service.registrarReporte(1L, 2L, new BigDecimal("-5.19"), new BigDecimal("-80.63"));

        assertThat(guardado.getUsuario()).isSameAs(usuario);
        assertThat(guardado.getRuta()).isSameAs(ruta);
        assertThat(guardado.getLatitud()).isEqualByComparingTo("-5.19");
        assertThat(guardado.getLongitud()).isEqualByComparingTo("-80.63");
    }

    @Test
    void obtenerUltimosPideUnaPaginaDelTamanoIndicado() {
        when(reporteGpsRepository.findByRuta_IdRutaOrderByFechaHoraDesc(eq(2L), any(Pageable.class)))
                .thenReturn(List.of());

        service.obtenerUltimos(2L, 5);

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(reporteGpsRepository).findByRuta_IdRutaOrderByFechaHoraDesc(eq(2L), captor.capture());
        assertThat(captor.getValue().getPageSize()).isEqualTo(5);
        assertThat(captor.getValue().getPageNumber()).isZero();
    }
}