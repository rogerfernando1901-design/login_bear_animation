import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; //3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Variable para el control de la visibilidad de la contraseña
  bool _obscure = true;

  //1.1 crear el cerebro de la animacion
  StateMachineController? _controller;
  //SMI: State Machine Input / Entradas de la maquina de estados
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  //3.3 Timer para detener la animacion de mirar
  Timer? _typingDebounce;

  //2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //Controles que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //Errores para mostrarlo en la UI
  String? _emailError;
  String? _passError;

  //Validadores
  bool isValidateEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //Dar Accion al boton
  void _onLogin() {
    //De lo que escribio el usuario quitar espacios en blanco
    final email = _emailCtrl.text = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    //4.6 Evaluiar los errores
    final eError = isValidateEmail(email) ? null : 'Invalid email';
    final pError = isValidPassword(password) ? null : 'Invalid password';

    //4.7 Avisar que hubo cambios
    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos del oso
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  //2.2 Activar el listeners
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',
                  stateMachines: ['Login Machine'],
                  //Vincular animaccion
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    //1.3 Verificar que inicio bien
                    if (_controller == null) return;
                    //Agregamos el controlador al escenario
                    artboard.addController(_controller!);
                    //Vinculamos variables
                    _isChecking = _controller?.findSMI('isChecking');
                    _isHandsUp = _controller?.findSMI('isHandsUp');
                    _trigSuccess = _controller?.findSMI('trigSuccess');
                    _trigFail = _controller?.findSMI('trigFail');
                    //3.4 Vincular la variable de mirada
                    _numLook = _controller?.findSMI('numLook');
                  },
                ),
              ),
              //para separar espacio
              SizedBox(height: 10),
              //Campo de texto para email
              TextField(
                //4.10 Enlazar controladores de texto
                controller: _emailCtrl,
                focusNode: _emailFocus,
                onChanged: (value) {
                  if (_isHandsUp != null) {
                    //No tapes los ojos al ver el email
                    // _isHandsUp?.change(false);
                  }
                  //Si isChecking no es nulO
                  if (_isChecking != null) {
                    //Activar el modo chismoso
                    _isChecking!.change(true);
                    final look = (value.length / 80 * 100.0).clamp(0.0, 100.0);
                    _numLook?.value = look;

                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  }
                },
                //para mostrar el tipo de teclado
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: _emailError,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              //Campo de texto para contraseña
              SizedBox(height: 10),
              TextField(
                controller: _passCtrl,

                focusNode: _passwordFocus,
                onChanged: (value) {
                  if (_isChecking != null) {
                    //No tapes los ojos al ver el email
                    // _isChecking?.change(false);
                  }
                  //Si isChecking no es nulO
                  if (_isHandsUp != null) {
                    //Activar el modo chismoso
                    _isHandsUp!.change(true);
                  }
                },
                obscureText: _obscure,
                //para mostrar el tipo de teclado
                decoration: InputDecoration(
                  errorText: _passError,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //Refrescar el estado
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    //para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 10),
              //Texto olvide mi contraseña
              SizedBox(
                width: size.width,
                child: const Text(
                  'Forgot your password?',
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 10),
              //Boton de login
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _onLogin,
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Dont have an account?'),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Sign Up',
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
    );
  }

  @override
  void dispose() {
    //2.3 Liberar los focusNode
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
