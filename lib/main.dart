import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CalculatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Parser class
class _Parser {
  int _pos = 0;
  late String _input;

  double parse(String input) {
    _pos = 0;
    _input = input;
    return _parseExpression();
  }

  double _parseExpression() {
    double result = _parseTerm();
    while (_pos < _input.length) {
      final op = _input[_pos];
      if (op == '+') {
        _pos++;
        result += _parseTerm();
      } else if (op == '-') {
        _pos++;
        result -= _parseTerm();
      } else {
        break;
      }
    }
    return result;
  }

  double _parseTerm() {
    double result = _parseFactor();
    while (_pos < _input.length) {
      final op = _input[_pos];
      if (op == '*') {
        _pos++;
        result *= _parseFactor();
      } else if (op == '/') {
        _pos++;
        result /= _parseFactor();
      } else {
        break;
      }
    }
    return result;
  }

  double _parseFactor() {
    if (_pos < _input.length && _input[_pos] == '(') {
      _pos++;
      double result = _parseExpression();
      _pos++; // consume ')'
      return result;
    }
    final buffer = StringBuffer();
    while (_pos < _input.length && RegExp(r'[0-9.]').hasMatch(_input[_pos])) {
      buffer.write(_input[_pos]);
      _pos++;
    }
    return double.parse(buffer.toString());
  }
}

// Calculator screen
class CalculatorHome extends StatefulWidget {
  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _input = '';
  String _result = '';
  List<String> _history = [];
  bool _showHistory = false;
  final FocusNode _focusNode = FocusNode();

  final List<String> _buttons = [
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    '0', '.', '(', ')',
    'C', '=', '+',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Handle keyboard input
  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.digit0) _onPressed('0');
      else if (key == LogicalKeyboardKey.digit1) _onPressed('1');
      else if (key == LogicalKeyboardKey.digit2) _onPressed('2');
      else if (key == LogicalKeyboardKey.digit3) _onPressed('3');
      else if (key == LogicalKeyboardKey.digit4) _onPressed('4');
      else if (key == LogicalKeyboardKey.digit5) _onPressed('5');
      else if (key == LogicalKeyboardKey.digit6) _onPressed('6');
      else if (key == LogicalKeyboardKey.digit7) _onPressed('7');
      else if (key == LogicalKeyboardKey.digit8) _onPressed('8');
      else if (key == LogicalKeyboardKey.digit9) _onPressed('9');
      else if (key == LogicalKeyboardKey.period) _onPressed('.');
      else if (key == LogicalKeyboardKey.add) _onPressed('+');
      else if (key == LogicalKeyboardKey.minus) _onPressed('-');
      // Fix: Use asterisk (*) for multiplication and slash (/) for division
      else if (key == LogicalKeyboardKey.asterisk) _onPressed('×');
      else if (key == LogicalKeyboardKey.slash) _onPressed('÷');
      else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.equal) _onPressed('=');
      else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) _onPressed('C');
      else if (key == LogicalKeyboardKey.parenthesisLeft) _onPressed('(');
      else if (key == LogicalKeyboardKey.parenthesisRight) _onPressed(')');
      // Handle backspace
      else if (key == LogicalKeyboardKey.backspace) {
        if (_input.isNotEmpty) {
          setState(() {
            _input = _input.substring(0, _input.length - 1);
          });
        }
      }
    }
  }

  void _onPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '';
      } else if (value == '=') {
        try {
          if (_input.isNotEmpty) {
            String newResult = _calculateResult(_input);
            _history.add('$_input = $newResult');
            // Keep only last 50 calculations
            if (_history.length > 50) {
              _history.removeAt(0);
            }
            _result = newResult;
            _input = ''; // Clear input after calculation
          }
        } catch (_) {
          _result = 'Error';
          _input = '';
        }
      } else {
        // If we just completed a calculation and user enters a number, start fresh
        if (_result.isNotEmpty && _input.isEmpty && RegExp(r'[0-9]').hasMatch(value)) {
          _result = '';
        }
        // If we just completed a calculation and user enters an operator, continue with result
        else if (_result.isNotEmpty && _input.isEmpty && _isOperator(value) && value != '=') {
          _input = _result + value;
          _result = '';
          return;
        }
        _input += value;
      }
    });
  }

  String _calculateResult(String expression) {
    try {
      final sanitized = expression.replaceAll('×', '*').replaceAll('÷', '/');
      final result = _Parser().parse(sanitized);

      // Format result to remove unnecessary decimal places
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        return result.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    } catch (_) {
      return 'Error';
    }
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _useHistoryResult(String historyItem) {
    final result = historyItem.split(' = ')[1];
    setState(() {
      _input = result;
      _showHistory = false;
    });
  }

  bool _isOperator(String x) => ['+', '-', '×', '÷', '='].contains(x);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.calculate : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
          if (_showHistory && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyPress,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // History or Display section
                    Container(
                      height: constraints.maxHeight * 0.35, // Fixed 35% of available height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _showHistory ? _buildHistoryView() : _buildDisplayView(),
                    ),
                    const SizedBox(height: 8),
                    // Buttons grid
                    Expanded(
                      child: _buildButtonGrid(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_history.length} calculations',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _history.isEmpty
              ? const Center(
            child: Text(
              'No calculations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          )
              : ListView.builder(
            reverse: true,
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final historyItem = _history[_history.length - 1 - index];
              return InkWell(
                onTap: () => _useHistoryResult(historyItem),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    historyItem,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Current input equation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _input.isEmpty ? (_result.isEmpty ? '0' : '') : _input,
              style: TextStyle(
                fontSize: _input.length > 15 ? 24 : 28,
                color: Colors.white70,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 10),
          // Current result (only shows after pressing = or when there's an error)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _result.isEmpty ? (_input.isEmpty ? '0' : '') : _result,
              style: TextStyle(
                fontSize: _result.length > 12 ? 32 : 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate button size based on available space
        double buttonSize = (constraints.maxWidth - 32) / 4; // 4 columns with spacing
        double gridHeight = (buttonSize + 8) * 5 - 8; // 5 rows with spacing

        return Container(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _buttons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final btn = _buttons[index];
              return Container(
                height: buttonSize,
                width: buttonSize,
                child: ElevatedButton(
                  onPressed: () => _onPressed(btn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOperator(btn)
                        ? Colors.orange
                        : btn == 'C'
                        ? Colors.red
                        : Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    btn,
                    style: TextStyle(
                      fontSize: btn.length > 1 ? 18 : 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}