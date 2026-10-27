package com.piuragopiura.piuragopiura_backend.service;

public interface ExportacionCongestionService {

    /** Histórico de congestión en un libro de Excel (.xlsx): una hoja por ruta y otra por tramo. */
    byte[] exportarExcel();
}
