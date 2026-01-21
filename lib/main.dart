import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:window_manager/window_manager.dart';

bool lockAspectRatio = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(400, 650),
      center: true,
      title: "Calculator",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      if (lockAspectRatio) await windowManager.setAspectRatio(4 / 6.5);
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

// Buttons in the calculator grid
final List<String> items = [
  '%', '^', '√', '÷',
  '7', '8', '9', '*',
  '4', '5', '6', '-',
  '1', '2', '3', '+',
  '0', '.', 'C', '=',
];

// State variables for calculation and UI
String currentCalculation = '';  // Expression displayed on bottom
String lastInput = '';           // Last input/result displayed on top
double? number1;
double? number2;
String operator = '';
String result = '';
bool num1neg = false;            // Flags for negative numbers
bool num2neg = false;
bool justSolved = false;         // Indicates if last action was calculation
String number1Str = '';          // String forms for input parsing
String number2Str = '';

// Performs calculation based on operator and operands
void solver(double? a, double? b, String op) {
  if (num1neg && a != null) a = -a;
  if (num2neg && b != null) b = -b;

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
        result = 'Error';  // Prevent division by zero
        return;
      }
      result = (left / (b ?? left)).toString();
      break;
    case '^':
      result = math.pow(left, (b ?? 2).toDouble()).toString();
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
}

// Handles input from calculator buttons and updates state accordingly
void input(String input) {
  // Handle input after a calculation was just solved
  if (justSolved) {
    if (RegExp(r'^[0-9.]+$').hasMatch(input)) {
      // Reset for new input if digit or decimal point pressed
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
      // Chain calculation if operator pressed next
      number1 = double.tryParse(result);
      operator = input;
      currentCalculation = '${number1.toString()}$input';
      lastInput = number1.toString();
      input = 's';  // Skip processing this input again below
    }
  }

  if (input != 's') {
    currentCalculation += input;

    // Update lastInput display based on input type
    if (RegExp(r'^[+\-*/÷^%√]$').hasMatch(input)) {
      if (number1 == null || (operator.isNotEmpty && number2 == null)) {
        lastInput += input;
      }
    } else if (operator.isNotEmpty && number2 == null) {
      lastInput = input;
    } else {
      lastInput += input;
    }
  }

  // Auto-solve when both operands and operator are present and new operator pressed
  if (number1 != null &&
      number2 != null &&
      operator.isNotEmpty &&
      RegExp(r'^[+\-*/÷^%√]$').hasMatch(input)) {
    solver(number1, number2, operator);
    lastInput = result;
    currentCalculation = result + input;
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

  // Process input based on button pressed
  switch (input) {
    case 'C': // Clear everything
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
    case '*':
    case '÷':
    case '^':
    case '√':
    case '%':
      if (number1 == null) {
        number1 = input == '%' ? 100 : 0;
        operator = input;
      } else if (operator.isEmpty) {
        operator = input;
      }
      break;

    case '-':
      if (number1 == null) {
        num1neg = true;  // Negative sign for first number
      } else if (operator.isEmpty) {
        operator = '-';
      } else {
        num2neg = true;  // Negative sign for second number
        currentCalculation += input;
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

    case '.': // Decimal input
      if (operator.isEmpty) {
        if (!number1Str.contains('.')) {
          number1Str = number1Str.isEmpty ? '0.' : '$number1Str.';
          number1 = double.tryParse(number1Str);
        }
      } else {
        if (!number2Str.contains('.')) {
          number2Str = number2Str.isEmpty ? '0.' : '$number2Str.';
          number2 = double.tryParse(number2Str);
        }
      }
      break;

    case 's': // Internal skip, do nothing
      break;

    default: // Digit input
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

// Home page widget displaying calculator UI
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Display for last input or result (top)
    final topDisplay = Container(
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

    // Display for full expression (bottom)
    final bottomDisplay = Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            topDisplay,
            bottomDisplay,
            const SizedBox(height: 12),
            // Grid of buttons
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => input(items[index])),
                    child: Text(
                      items[index],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
