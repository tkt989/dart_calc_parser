
import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:calc_parser/parser.dart';

N(n) => new Number(n);

fn(FuncManager fm, String name) => fm.functions[name];

var isParseError = predicate((e) => e is ParseError, 'is a ParseError');

main() {
  FuncManager fm= new FuncManager();
  fm.addFunction('+', 2, (x, y) => x + y);
  fm.addFunction('-', 2, (x, y) => x - y);
  fm.addFunction('*', 2, (x, y) => x * y);
  fm.addFunction('/', 2, (x, y) => x / y);
  fm.addFunction('sqrt', 1, (x) => sqrt(x));
  
  p(String str, {FuncManager fm_}) {
    if (fm_ == null) {
      return new Parser(str, fm);
    } else {
      return new Parser(str, fm_);
    }
  }

  defBinOp(func, x, y) {
    if (x is num) x = N(x);
    if (y is num) y = N(y);
    return new FuncExp(fm.getFunction(func), [x, y]);
  }
  plus(x, y) => defBinOp('+', x, y);
  minus(x, y) => defBinOp('-', x, y);
  mul(x, y) => defBinOp('*', x, y);
  div(x, y) => defBinOp('/', x, y);

  group('consructor', () {
    test('valid', () {
      new Parser('1+2');
    });
  });
  
  group('parse_expr', () {
    test('valid', () {
      expect(p('2+3').parse_expr(), equals(plus(2,3)));
      expect(p('10-2').parse_expr(), equals(minus(10,2)));
      
      expect(p('43*33/45+23-3*3').parse_expr(),
          equals(minus(plus(div(mul(43,33),45),23),mul(3,3))));
      expect(p('43 * 33 / 45 + 23 - 3 * 3 ').parse_expr(),
          equals(minus(plus(div(mul(43,33),45),23),mul(3,3))));
      
      expect(p('1*2+3-4/5').parse_expr(),
          equals(minus(plus(mul(1,2),3),div(4,5))));
      
      expect(p('(1+2)*3').parse_expr(),
          equals(mul(plus(1,2),3)));
    });
  });
  
  group('parse_expr2', () {
    test('valid', () {
      expect(p('2*3').parse_expr2(), equals(mul(2, 3)));
      expect(p('1/3').parse_expr2(), equals(div(1, 3)));
      
      expect(p('2').parse_expr2(), equals(N(2)));
      
      expect(p('1*2*3').parse_expr2(),
          equals(mul(mul(1,2),3)));
      expect(p('34*53*94/21/43*2').parse_expr2(),
          equals(mul(div(div(mul(mul(34,53),94),21),43),2)));
    });
  });
  
  group('parse_number', () {
    test('valid integer', () {
      expect(p('1').parse_number(), equals(N(1)));
      expect(p('0').parse_number(), equals(N(0)));
      expect(p('-1').parse_number(), equals(N(-1)));
      expect(p('-1234').parse_number(), equals(N(-1234)));
      });
    
    test('valid float', () {
      expect(p('12.3').parse_number(), equals(N(12.3)));
      expect(p('-3.14').parse_number(), equals(N(-3.14)));
    });
    
    test('not valid', () {
      expect(() => p('x').parse_number(), throwsA(isParseError));
    });
  });
  
  group('parse_function', () {
    test('valid', () {
      expect(p('sqrt(1)', fm_: fm).parse_function(), equals(new FuncExp(fn(fm, 'sqrt'),[N(1)])));
      expect(p('sqrt(1+2*2/3)', fm_: fm).parse_function(),
          equals(new FuncExp(fn(fm, 'sqrt'),[plus(1,div(mul(2,2),3))])));
    });
  });
  
  group('parse_arguments', () {
    test('valid', () {
      expect(p('1,2').parse_arguments(), equals([N(1),N(2)]));
      expect(p('1+2,3*4').parse_arguments(),
          equals([plus(1,2),mul(3,4)]));
    });
  });
}