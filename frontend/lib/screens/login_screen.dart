import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';
//H1.B Importar la pantalla de registro
import 'signup_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Control para mostrar/Ocultar contraseña
  bool _isObscure = true;

  // 1.1 Máquina estados / Cerebro de la animación
  StateMachineController? _controller;

  // StateMachineInputss ()
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener el recorrido de la mirada
  Timer? _typingDebounce;
  

  //2.1 Crear Variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus= FocusNode();

  //4.1 Controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

   //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;

  //H1.A Mensaje global único (OWASP): nunca decimos si falló el correo o la contraseña
  static const String _genericError =
      'Credenciales inválidas. Verifica tu correo y contraseña.';

  //H1.A Mostrar un mensaje global en un SnackBar
  void _showMessage(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    //Recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    //4.6 Cerrar teclado y oso en forma neutral
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //H1.A Solo validamos que los campos no estén vacíos (sin Regex en el Login)
    if (email.isEmpty || pass.isEmpty) {
      _trigFail?.fire();
      _showMessage('Ingresa tu correo y tu contraseña.');
      return;
    }

    //5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      //5.5 Autenticar usuario en Firebase (esperamos un par de segundos para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      //5.6 Apagar loading, disparar éxito del osito y esperar a que termine su animación
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar a la pantalla de productos de Spring Boot
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } catch (e) {
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      //H1.A Mismo mensaje genérico para cualquier error de Firebase
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _trigFail?.fire();
      _showMessage(_genericError);
    }
  }

  //H1.C Recuperar contraseña con un Dialog
  Future<void> _showForgotPasswordDialog() async {
    final resetCtrl = TextEditingController(text: emailCtrl.text.trim());

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: resetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              } catch (_) {
                // Ignoramos el error a propósito: no revelamos si el correo existe
              }
              //Mensaje neutral (OWASP: evitar enumeración de cuentas)
              if (!mounted) return;
              _showMessage(
                'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
                color: Colors.green,
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

//2.2 Crear los oyentes (listener)
  @override
  void initState(){
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus){
        if (_isHandsUp != null){
          _isHandsUp?.change(false);

        //3.3 Mirada neutral
        _numLook?.value=50.0; 
        }
      }
    });

    _passwordFocus.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
    
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login_bear.riv',
                    stateMachines: const ['Login Machine'],
                    // 1.2 Vincular la animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      // 1.3 Verificar que inició bien
                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      // 1.4 Vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Email
                TextField(
                  //4.8 Vincular el controller
                  controller: emailCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _emailFocus,
                  // 1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      // No tapes los ojos al ver el email
                      //_isHandsUp!.change(false);
                    }

                    if (_isChecking != null) {
                      //Activa modo chismoso
                      _isChecking!.change(true);
                      //3.4 Implementar recorrido con la mirada
                      //Ajuste de límites del 0 al 100
                      //80 medida de calibración. Clamp es un rango
                      final look = (value.length/80.0*100.0).clamp(
                        0.0,
                        100.0
                        );
                        _numLook?.value=look;

                        //3.5 Debounce: Si vuelve a teclear, reinicia el contador
                        _typingDebounce?.cancel();
                        //Crear el nuevo timer
                        _typingDebounce = Timer(const Duration(seconds: 3), (){
                          //Si se cierra la pantalla, termina la ejecución.
                          if (!mounted) return;
                          //Mirada neutra
                          _isChecking?.change(false);
                        });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Contraseña
                TextField(
                  //4.8 Vincular el controller
                  controller: passCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _passwordFocus,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isChecking != null) {
                      // No actives el modo chismoso en contraseña
                      //_isChecking!.change(false);
                    }

                    if (_isHandsUp != null) {
                      _isHandsUp!.change(true);
                    }
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        // Refrescar el ícono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //H1.C "Forgot password?" ahora abre el diálogo
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //Botón de Login
                MaterialButton(
                  //Toma todo el ancho posible
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  //5.9 Mostrar CircularProgressIndicator si está cargando, o el texto Login
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account"),
                      TextButton(
                        //H1.B Navegar al registro con push (para poder regresar)
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
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
    //2.4 Liberar memoria o recursos en los FocusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    //3.5 Liberar
    _typingDebounce?.cancel();
    //Liberar los controllers de texto
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }


}