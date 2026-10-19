package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioRegistradoRepository extends JpaRepository<UsuarioRegistrado, Long> {
    Optional<UsuarioRegistrado> findByEmail(String email);
    boolean existsByEmail(String email);
}