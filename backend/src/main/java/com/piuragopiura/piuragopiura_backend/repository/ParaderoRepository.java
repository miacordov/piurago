package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.Paradero;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ParaderoRepository extends JpaRepository<Paradero, Long> {
    List<Paradero> findByRuta_IdRutaOrderByOrdenSecuencialAsc(Long idRuta);
}