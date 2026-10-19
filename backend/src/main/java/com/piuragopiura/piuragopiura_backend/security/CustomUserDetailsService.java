package com.piuragopiura.piuragopiura_backend.security;

import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioAnonimoRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRegistradoRepository;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UsuarioRegistradoRepository usuarioRegistradoRepository;
    private final UsuarioAnonimoRepository usuarioAnonimoRepository;

    public CustomUserDetailsService(UsuarioRegistradoRepository usuarioRegistradoRepository,
                                    UsuarioAnonimoRepository usuarioAnonimoRepository) {
        this.usuarioRegistradoRepository = usuarioRegistradoRepository;
        this.usuarioAnonimoRepository = usuarioAnonimoRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        if (username.startsWith(JwtUtil.PREFIJO_ANONIMO)) {
            String deviceUuid = username.substring(JwtUtil.PREFIJO_ANONIMO.length());
            UsuarioAnonimo anonimo = usuarioAnonimoRepository.findByDeviceUuid(deviceUuid)
                    .orElseThrow(() -> new UsernameNotFoundException("Dispositivo no registrado: " + deviceUuid));

            return new UsuarioAutenticado(username, "",
                    List.of(new SimpleGrantedAuthority("ROLE_ANONIMO")), anonimo.getIdUsuario());
        }

        UsuarioRegistrado usuario = usuarioRegistradoRepository.findByEmail(username)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + username));

        return new UsuarioAutenticado(usuario.getEmail(), usuario.getPasswordHash(),
                List.of(new SimpleGrantedAuthority("ROLE_REGISTRADO")), usuario.getIdUsuario());
    }
}