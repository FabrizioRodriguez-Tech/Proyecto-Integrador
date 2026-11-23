import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//H1.B Pantalla de Registro: aquí SÍ mostramos errores por campo y las reglas
//de la contraseña, para ayudar al usuario a crear una cuenta válida.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //Llave del formulario para ejecutar todas las validaciones juntas
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  //Dominio institucional obligatorio
  static const String _domain = '@tecdesoftware.edu.mx';

  //Reglas de la contraseña (se muestran en pantalla con ✓ / ✗)
  bool get _hasMinLength => passCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(passCtrl.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(passCtrl.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(passCtrl.text);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(passCtrl.text);

  //Validador del correo
  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'Ingresa tu correo';
    final re = RegExp(r'^[^\s@]+@tecdesoftware\.edu\.mx$');
    if (!re.hasMatch(email)) return 'Usa tu correo institucional ($_domain)';
    return null;
  }

  //Validador de la contraseña
  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa una contraseña';
    if (!(_hasMinLength && _hasUpper && _hasLower && _hasNumber && _hasSymbol)) {
      return 'La contraseña no cumple todas las reglas';
    }
    return null;
  }

  //Validador de confirmar contraseña
  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
    if (value != passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  void _showMessage(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  //Registrar al usuario en Firebase
  Future<void> _onSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim().toLowerCase(),
        password: passCtrl.text,
      );

      //Firebase inicia sesión automáticamente al crear la cuenta.
      //Cerramos sesión para que el usuario entre desde el Login.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      _showMessage('Cuenta creada. Ya puedes iniciar sesión.', color: Colors.green);
      //Regresar al Login
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      //En el registro sí damos mensajes específicos
      final message = switch (e.code) {
        'email-already-in-use' => 'Ese correo ya tiene una cuenta registrada.',
        'invalid-email' => 'El formato del correo no es válido.',
        'weak-password' => 'La contraseña es muy débil.',
        'network-request-failed' => 'Sin conexión. Revisa tu internet.',
        _ => 'No se pudo crear la cuenta (${e.code}).',
      };
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //Una fila de regla con ✓ verde o ✗ gris
  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: ok ? Colors.green : Colors.black54)),
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Correo
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: _decoration('usuario$_domain', Icons.email),
                ),
                const SizedBox(height: 12),

                //Contraseña (onChanged refresca las reglas en pantalla)
                TextFormField(
                  controller: passCtrl,
                  obscureText: _isObscure,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration(
                    'Contraseña',
                    Icons.lock,
                    suffix: IconButton(
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                      icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                //Reglas de la contraseña
                const Text('Tu contraseña debe tener:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _rule('Mínimo 8 caracteres', _hasMinLength),
                _rule('Una letra mayúscula', _hasUpper),
                _rule('Una letra minúscula', _hasLower),
                _rule('Un número', _hasNumber),
                _rule('Un símbolo (ej. !@#\$%)', _hasSymbol),
                const SizedBox(height: 12),

                //Confirmar contraseña
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: _isObscure,
                  validator: _validateConfirm,
                  decoration: _decoration('Confirmar contraseña', Icons.lock_outline),
                ),
                const SizedBox(height: 20),

                //Botón de registro
                MaterialButton(
                  minWidth: double.infinity,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onSignUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign up',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
