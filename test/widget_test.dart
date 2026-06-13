import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_camiones/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construimos la app pasándole valores simulados (falsos) para la sesión
    await tester.pumpWidget(
      const MyApp(
        estaLogueado:
            false, // Simulamos que el usuario no está logueado para la prueba
        idUsuario: null,
        rol: null,
      ),
    );

    // Nota: El código de abajo es el test por defecto de Flutter (el contador).
    // Como tu app ya no tiene un contador, estas validaciones van a fallar al ejecutar 'flutter test',
    // pero al menos tu proyecto ya compilará perfectamente sin errores.

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
