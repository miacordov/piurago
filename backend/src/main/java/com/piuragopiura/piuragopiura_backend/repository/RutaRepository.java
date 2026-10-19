package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.Ruta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RutaRepository extends JpaRepository<Ruta, Long> {
    List<Ruta> findByActivaTrue();
}