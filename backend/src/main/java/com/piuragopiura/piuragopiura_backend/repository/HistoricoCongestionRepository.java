package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HistoricoCongestionRepository extends JpaRepository<HistoricoCongestion, Long> {

    List<HistoricoCongestion> findByRuta_IdRutaOrderByFechaCalculoDesc(Long idRuta);

    Optional<HistoricoCongestion> findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
            Long idRuta, String franjaHoraria, String diaSemana
    );

    Optional<HistoricoCongestion> findByRuta_IdRutaAndParadero_IdParaderoAndFranjaHorariaAndDiaSemana(
            Long idRuta, Long idParadero, String franjaHoraria, String diaSemana
    );

    List<HistoricoCongestion> findByDiaSemana(String diaSemana);
}

