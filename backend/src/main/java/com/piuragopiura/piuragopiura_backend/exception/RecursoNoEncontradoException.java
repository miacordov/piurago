package com.piuragopiura.piuragopiura_backend.exception;

/** El recurso pedido no existe (por ejemplo, una ruta). Se responde con 404. */
public class RecursoNoEncontradoException extends RuntimeException {
    public RecursoNoEncontradoException(String mensaje) {
        super(mensaje);
    }
}
