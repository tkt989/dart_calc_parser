library parser;

import 'package:string_scanner/string_scanner.dart';

/*
 * value ::= number
 *         | '(' expr ')'
 *         | function
 * function ::= '\w+(' arguments ')'
 * arguments ::= '\w+' {',\w+'}*
 * expr ::= expr2 {('+'|'-') expr2}*
 * expr2 ::= value {('*'|'/') value}*
 */

FuncManager _defaultFM = new FuncManager(
    [
     ['+', 2, (x, y) => x + y],
     ['-', 2, (x, y) => x - y],
     ['*', 2, (x, y) => x * y],
     ['/', 2, (x, y) => x / y]
    ]
    );

class Parser {
  static final SPACE = r'\s*';
  static final NUMBER = r'(-?\d+(\.\d+)?)';
  static final PAREN_START = r'\(';
  static final PAREN_END = r'\)';
  static final OP = r'(\+|-)';
  static final OP_2 = r'(\*|/)';
  static final FUNCTION_START = r'(\w[a-zA-Z0-9]*)\s*\(';
  static final COMMA = r'(,)';
  
  StringScanner _scanner;
  FuncManager _funcManager;
  
  Parser(String str, [FuncManager funcManager]) {
    this._scanner = new StringScanner(str);
    this._funcManager = (funcManager == null) ? _defaultFM : funcManager;
  }
  
  _ignoreSpaceScan(regexp) {
    _scanner.skip(SPACE);
    return _scanner.scan(regexp);
  }
  
  _ignoreSpaceCheck(regexp) {
    _scanner.skip(SPACE);
    return _scanner.check(regexp);
  }
  
  Exp parse() => parse_expr();
  
  Exp parse_expr() {
    Exp val1 = parse_expr2();
    
    Exp result = val1;
    while (_ignoreSpaceScan(OP) != null) {
      Func func = _funcManager.getFunction(_scanner[1]);
      Exp val2 = parse_expr2();
      
      result = new FuncExp(func, [result, val2]);
    }
    
    return result;
  }
  
  Exp parse_expr2() {
    Exp val1 = parse_value();
    
    Exp result = val1;
    while (_ignoreSpaceScan(OP_2) != null) {
      Func func = _funcManager.getFunction(_scanner[1]);
      Exp val2 = parse_value();
      
      result = new FuncExp(func, [result, val2]);
    }
    
    return result;
  }
  
  Exp parse_value() {
    if        (_ignoreSpaceCheck(NUMBER) != null) {
      return parse_number();
    } else if (_ignoreSpaceCheck(PAREN_START) != null) {
      return parse_paren();
    } else if (_ignoreSpaceCheck(FUNCTION_START) != null) {
      return parse_function();
    }
    throw new ParseError('${_scanner.position}: parse error');
  }
  
  Exp parse_number() {
    if (_ignoreSpaceScan(NUMBER) == null)
      throw new ParseError('${_scanner.position}: ${_scanner.string[_scanner.position]} is not number');
    return new Number(num.parse(_scanner[1]));
  }
  
  Exp parse_paren() {
    if (_ignoreSpaceScan(PAREN_START) == null) 
      throw new ParseError('${_scanner.position}: ${_scanner.string[_scanner.position]} is not paren');
    var val = parse_expr();
    
    if (_ignoreSpaceScan(PAREN_END) == null) throw new ParseError('${_scanner.position}: paren is not closed');
    return val;
  }
  
  Exp parse_function() {
    if (_ignoreSpaceScan(FUNCTION_START) == null) {
      throw new ParseError('${_scanner.position}: ${_scanner.string[_scanner.position]} is not function');
    }
    
    String name = _scanner[1];
    Func func = _funcManager.getFunction(name);
    if (func == null)
      throw new ParseError('${_scanner.position}: no such function: $name');
    
    List<Exp> args = parse_arguments();
    
    if (func.num_args != args.length)
      throw new ParseError('${_scanner.position}: incorrect number of arguments: ${func.name}');
    
    var result = new FuncExp(func, args);
    if (_ignoreSpaceScan(PAREN_END) == null) throw new ParseError('${_scanner.position}: paren is not closed');
    return result;
  }
  
  List<Exp> parse_arguments() {
    List<Exp> result = [];
    result.add(parse_expr());
    
    while (_ignoreSpaceScan(COMMA) != null) {
      result.add(parse_expr());
    }
    return result;
  }
}

class FuncManager {
  Map functions = {};
  
  FuncManager([List initial]) {
    if (initial == null) return;
    initial.forEach((array) {
      addFunction(array[0], array[1], array[2]);
    });
  }
  
  addFunction(String name, int num_args, Function func) {
    functions[name] = new Func(name, num_args, func);
  }
  
  Func getFunction(String name) => functions[name];
}

class Func {
  String name;
  int num_args;
  Function function;
  
  Func(this.name, this.num_args, this.function);
  toString() => this.name;
}

abstract class Exp {
  num eval();
}

class Number extends Exp {
  num value;
  Number(this.value);
  
  num eval() => value;
  
  bool operator==(other) => this.value == other.value;
  
  String toString() => value.toString();
}

class FuncExp extends Exp {
  Func func;
  List<Exp> arguments;
  
  FuncExp(this.func, this.arguments);
  
  num eval() => Function.apply(func.function,  arguments.map((e) => e.eval()).toList());
  
  toString() {
    String result = '${func.toString()}(';
    arguments.forEach((exp) {
      result += exp.toString() + ',';
    });
    result = result.substring(0, result.length-1);
    result += ')';
    return result;
  }
  bool operator==(FuncExp other) {
    int idx = 0;
    return this.func == other.func &&
        this.arguments.every((e) {
      return e == other.arguments[idx++];
    });
  }
}

class ParseError extends StateError {
  ParseError(String message) : super(message);
}