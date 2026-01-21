import 'package:flutter/material.dart'; // Flutter UI framework
import 'dart:math' as math; // Advanced math functions like root and power
import 'dart:io'; // Operating system detection
import 'package:window_manager/window_manager.dart'; // Desktop window management

bool lockAspectRatio = true; // Flag to lock the window aspect ratio on desktop platforms

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Configure window options for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 650),
      center: true,
      title: "Calculator",
    );

    // Show window and set aspect ratio if locked
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();

      if (lockAspectRatio) {
        await windowManager.setAspectRatio(4 / 6.5);
      }
    });
  }

  runApp(const MyApp());
}

// Root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

// Calculator buttons in order
var items = [
  '%', '^', '√', '÷', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', 'C', '=',
];

// State variables for calculation
var currentCalculation = ''; // Full expression shown on screen
var lastInput = ''; // Last input/result shown on display
double? number1;
double? number2;
String operator = '';
String result = '';
bool num1neg = false; // Whether number1 is negative
bool num2neg = false; // Whether number2 is negative
bool justSolved = false; // Flag to indicate last action was solve
String number1Str = ''; // String form of first number (for decimal input)
String number2Str = ''; // String form of second number

// Core solver function handling all supported operations
void solver(double? a, double? b, String op) {
  // Apply negative flags
  if (num1neg && a != null) a = -a;
  if (num2neg && b != null) b = -b;

  print('$a $op $b');
  final double left = a ?? 0;

  switch (op) {
    case '+':
      result = (left + (b ?? left)).toString();
      break;
    case '-':
      result = (left - (b ?? left)).toString();
      break;
    case '*':
      result = (left * (b ?? left)).toString();
      break;
    case '÷':
      if ((b ?? left) == 0) {
        result = 'Error'; // Avoid division by zero
        return;
      } else {
        result = (left / (b ?? left)).toString();
      }
      break;
    case '^':
      result = math.pow(left.toDouble(), (b ?? 2).toDouble()).toString();
      break;
    case '√':
      if (a == null || a == 0) {
        result = math.sqrt(b ?? 0).toString();
      } else if (b == null) {
        result = math.sqrt(a).toString();
      } else {
        result = (a * math.sqrt(b)).toString();
      }
      break;
    case '%':
      b ??= 0;
      result = (left * (b / 100)).toString();
      break;
    default:
      throw Exception('Unknown operator');
  }
  // Note: negative flags are not reset here to preserve state for testing
}

// Handles input for each button press and updates calculation state
void input(String input) {
  if (justSolved == true) {
    // After solving, clear or chain calculation based on next input
    if (RegExp(r'^[0-9.]+$').hasMatch(input)) {
      // Clear for new input if digit or dot
      currentCalculation = '';
      lastInput = '';
      number1 = null;
      number2 = null;
      operator = '';
      result = '';
      num1neg = false;
      num2neg = false;
      number1Str = '';
      number2Str = '';
    } else if (RegExp(r'^[+\-*/÷^%√]$').hasMatch(input)) {
      // Chain calculation starting from previous result
      number1 = double.tryParse(result);
      operator = input;
      currentCalculation = '';
      currentCalculation += number1.toString();
      currentCalculation += input;
      lastInput = number1.toString();
      input = 's'; // Skip adding this input again below
    } else if (input == 's') {
      input = 's'; // Explicit skip
    }
  }

  if (!(input == 's')) {
    currentCalculation += input;
    if (RegExp(r'^[+\-*/÷^%√]$').hasMatch(input)) {
      if (number1 == null) {
        lastInput += input;
      } else if (operator.isNotEmpty && number2 == null) {
        lastInput += input;
      }
    } else if (operator.isNotEmpty && number2 == null) {
      lastInput = input;
    } else {
      lastInput += input;
    }
  }

  // Auto-solve when operator and both numbers exist and a new operator (not '=') is pressed
  if (number1 != null && number2 != null && operator.isNotEmpty && RegExp(r'^[+\-*/÷^%√]$').hasMatch(input)) {
    solver(number1, number2, operator);
    lastInput = result;
    currentCalculation = result;
    currentCalculation += input;
    number1 = double.tryParse(result);
    number2 = null;
    operator = input != '=' ? input : '';
    justSolved = true;
    number1Str = result;
    number2Str = '';
    if (input == '=') {
      number1 = null;
      operator = '';
    }
  }

  justSolved = false;

  switch (input) {
    case 'C': // Clear all
      currentCalculation = '';
      lastInput = '';
      number1 = null;
      number2 = null;
      operator = '';
      result = '';
      num1neg = false;
      num2neg = false;
      justSolved = false;
      number1Str = '';
      number2Str = '';
      break;
    case '+':
      if (number1 == null) {
        number1 = 0;
        operator = '+';
      } else if (number2 == null) {
        operator = '+';
      }
      break;
    case '-':
      if (number1 == null) {
        num1neg = true; // Negative sign for first number
      } else if (operator.isEmpty) {
        operator = '-';
      } else {
        num2neg = true; // Negative sign for second number
        currentCalculation += input;
      }
      break;
    case '*':
      if (number1 == null) {
        number1 = 0;
        operator = '*';
      } else if (operator.isEmpty) {
        operator = '*';
      }
      break;
    case '÷':
      if (number1 == null) {
        number1 = 0;
        operator = '÷';
      } else if (operator.isEmpty) {
        operator = '÷';
      }
      break;
    case '^':
      if (number1 == null) {
        number1 = 0;
        operator = '^';
      } else if (operator.isEmpty) {
        operator = '^';
      }
      break;
    case '√':
      if (number1 == null) {
        number1 = 0;
        operator = '√';
      } else if (operator.isEmpty) {
        operator = '√';
      }
      break;
    case '%':
      if (number1 == null) {
        number1 = 100;
        operator = '%';
      } else if (operator.isEmpty) {
        operator = '%';
      }
      break;
    case '=': // Calculate result
      solver(number1, number2, operator);
      lastInput = result;
      currentCalculation = ('$number1$operator$number2=').replaceAll('null', '');
      number1 = null;
      number2 = null;
      operator = '';
      justSolved = true;
      number1Str = '';
      number2Str = '';
      break;
    case '.': // Handle decimal points
      if (operator.isEmpty) {
        if (number1Str.contains('.')) break;
        if (number1Str.isEmpty) number1Str = '0';
        number1Str += '.';
        number1 = double.tryParse(number1Str);
      } else {
        if (number2Str.contains('.')) break;
        if (number2Str.isEmpty) number2Str = '0';
        number2Str += '.';
        number2 = double.tryParse(number2Str);
      }
      break;
    case 's': // Skip input, used internally for flow control
      break;
    default: // Append digit input to the appropriate number string
      if (RegExp(r'^[0-9]+$').hasMatch(input)) {
        if (operator.isEmpty) {
          number1Str += input;
          number1 = double.tryParse(number1Str);
        } else {
          number2Str += input;
          number2 = double.tryParse(number2Str);
        }
      }
      break;
  }
}

// Home page widget with UI for the calculator
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Top display shows last input/result
    Widget topDisplay = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lastInput,
        style: const TextStyle(fontSize: 28, color: Colors.black),
      ),
    );

    // Bottom display shows the full current calculation expression
    Widget bottomDisplay = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentCalculation,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            topDisplay,
            bottomDisplay,
            const SizedBox(height: 12),
            // Grid of calculator buttons
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        input(items[index]);
                      });
                    },
                    child: Text(
                      items[index],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple testing helper to validate operations
void test(String label, double? a, double? b, String op, String expected, {bool num1Neg = false, bool num2Neg = false}) {
  number1 = a;
  number2 = b;
  operator = op;
  num1neg = num1Neg;
  num2neg = num2Neg;

  solver(number1, number2, operator);

  final actual = result;
  final ok = actual == expected ? 'OK' : 'FAIL';

  print('$label = $actual [$ok]');
}

// Runs a suite of basic tests, printing results
void runTests() {
  print('--- BASIC OPERATIONS ---');
  test('1.0 + 2.0', 1, 2, '+', '3.0');
  test('5.0 - 3.0', 5, 3, '-', '2.0');
  test('4.0 * 6.0', 4, 6, '*', '24.0');
  test('8.0 ÷ 2.0', 8, 2, '÷', '4.0');

  print('\n--- DECIMALS ---');
  test('1.5 + 2.2', 1.5, 2.2, '+', '3.7');
  test('0.3 + 0.2', 0.3, 0.2, '+', '0.5');
  test('2.5 * 2.0', 2.5, 2.0, '*', '5.0');

  print('\n--- NEGATIVES ---');
  test('-5.0 + 3.0', 5, 3, '+', '-2.0', num1Neg: true);
  test('-4.0 * -2.0', 4, 2, '*', '8.0', num1Neg: true, num2Neg: true);

  print('\n--- POWER / ROOT ---');
  test('2.0 ^ 3.0', 2, 3, '^', '8.0');
  test('null √ 9.0', null, 9, '√', '3.0');

  print('\n--- PERCENT ---');
  test('50.0 % 10.0', 50, 10, '%', '5.0');

  print('\n--- DIVISION BY ZERO ---');
  test('5.0 ÷ 0.0', 5, 0, '÷', 'Error');
  input('C');
  print('\n--- DONE ---');
}
