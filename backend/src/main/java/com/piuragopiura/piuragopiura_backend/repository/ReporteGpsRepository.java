package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReporteGpsRepository extends JpaRepository<ReporteGps, Long> {

    List<ReporteGps> findByRuta_IdRutaOrderByFechaHoraDesc(Long idRuta, Pageable pageable);

    List<ReporteGps> findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
            Long idRuta, LocalDateTime desde, Pageable pageable);

    List<ReporteGps> findByUsuario_IdUsuarioOrderByFechaHoraDesc(Long idUsuario);
}