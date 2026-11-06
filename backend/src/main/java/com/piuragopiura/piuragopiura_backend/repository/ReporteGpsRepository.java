package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReporteGpsRepository extends JpaRepository<ReporteGps, Long> {

    /**
     * Borra de una vez (un solo DELETE, sin cargar las entidades) los reportes con
     * fecha anterior a {@code limite} y devuelve cuántos borró. Usa idx_reporte_gps_fecha.
     */
    @Modifying
    @Query("DELETE FROM ReporteGps r WHERE r.fechaHora < :limite")
    int borrarAnterioresA(@Param("limite") LocalDateTime limite);

    List<ReporteGps> findByRuta_IdRutaOrderByFechaHoraDesc(Long idRuta, Pageable pageable);

    List<ReporteGps> findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
            Long idRuta, LocalDateTime desde, Pageable pageable);

    List<ReporteGps> findByUsuario_IdUsuarioOrderByFechaHoraDesc(Long idUsuario);
}