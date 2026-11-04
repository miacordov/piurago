package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReporteGpsRepository extends JpaRepository<ReporteGps, Long> {

    List<ReporteGps> findByRuta_IdRutaOrderByFechaHoraDesc(Long idRuta, Pageable pageable);

    List<ReporteGps> findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
            Long idRuta, LocalDateTime desde, Pageable pageable);

    List<ReporteGps> findByUsuario_IdUsuarioOrderByFechaHoraDesc(Long idUsuario);

    /**
     * Último reporte de cada colaborador de la ruta posterior a {@code desde}. Si un
     * colaborador tiene dos reportes con la misma hora, vienen los dos.
     */
    @Query("""
            SELECT r FROM ReporteGps r
            WHERE r.ruta.idRuta = :idRuta
              AND r.fechaHora > :desde
              AND r.fechaHora = (
                  SELECT MAX(r2.fechaHora) FROM ReporteGps r2
                  WHERE r2.ruta.idRuta = :idRuta
                    AND r2.usuario.idUsuario = r.usuario.idUsuario
                    AND r2.fechaHora > :desde)
            ORDER BY r.fechaHora DESC
            """)
    List<ReporteGps> findUltimaPorColaborador(@Param("idRuta") Long idRuta,
                                              @Param("desde") LocalDateTime desde);
}