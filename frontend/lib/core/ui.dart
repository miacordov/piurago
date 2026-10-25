import 'package:flutter/material.dart';

/// Avisa que una función todavía no está construida.
void mostrarProximamente(BuildContext context, String funcion) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$funcion estará disponible en una próxima versión.'),
      ),
    );
}
