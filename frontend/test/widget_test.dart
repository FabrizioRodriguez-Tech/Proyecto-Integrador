// Prueba básica: la pantalla de registro se dibuja y muestra las reglas de la contraseña.
// (No probamos el Login aquí porque necesita Firebase inicializado.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:login_rive_animation/screens/signup_screen.dart';

void main() {
  testWidgets('SignUpScreen muestra el formulario y las reglas', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
