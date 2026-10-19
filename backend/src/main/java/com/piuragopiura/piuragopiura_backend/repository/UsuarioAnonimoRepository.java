package com.piuragopiura.piuragopiura_backend.repository;

import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioAnonimoRepository extends JpaRepository<UsuarioAnonimo, Long> {
    Optional<UsuarioAnonimo> findByDeviceUuid(String deviceUuid);
}