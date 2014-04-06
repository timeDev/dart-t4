part of t4;

class _T4Engine {
  TextTemplate template;
  String _preOut;
  List tokens;
  int progress;
  
  _T4Engine(this.template) {
    progress = 0;
  }
  
  StringBuffer output, body;
  List params, imports;
  String state;
  
  void tokenize1() {
    tokens = [];
    var source = template.source;
    var pos = 0;
    while(pos < source.length - 1) {
      var i = source.indexOf('<#', pos);
      if(i == -1) {
        tokens.add(source.substring(pos));
        break;
      } else {
        if(i > 0) {
          tokens.add(source.substring(pos, i));
        }
        var e = source.indexOf('#>', i);
        tokens.add(source.substring(i, e + 2));
        pos = e + 2;
      }
    }
    progress = 1;
  }
  
  void tokenize2() {
    if(progress < 1) throw 'Not ready';
    var tokensNew = [];
    for(int i = 0; i < tokens.length; i++) {
      String t = tokens[i];
      if(t.startsWith('<#')) {
        t = '<#' + t.substring(2, t.length - 2).trim() + '#>';
        //print(t);
        var expression = new RegExp(r'^<#=([\S\s]*)#>').firstMatch(t);
        var directive = new RegExp(r'^<#@\s*([A-Za-z0-9-]+)\s+([A-Za-z0-9.:_$ /"' + '\'' + r'-]+)#>').firstMatch(t);
        var control = new RegExp(r'^<#([\S\s]*)#>').firstMatch(t);
        if(expression != null) {
          tokensNew.addAll(['<#=', expression.group(1), '#>']);
        } else if(directive != null) {
          tokensNew.addAll(['<#@', directive.group(1), directive.group(2), '#>']);
        } else if(control != null) {
          tokensNew.addAll(['<#', control.group(1), '#>']);
        } else {
          throw 'Invalid control block';
        }
      } else {
        tokensNew.add(t);
      }
    }
    tokens = tokensNew;
    progress = 2;
  }
  
  void preProcess() {
    if(progress < 2) throw 'Not ready';
    params = [];
    imports = [];
    body = new StringBuffer();
    var tQ = new Queue.from(tokens);
    while(tQ.isNotEmpty) {
      var t = tQ.removeFirst();
      if(t == '<#') { // <#, cbBody, #>
        if(tQ.length < 2) throw 'Unexpected EOF';
        var cbBody = tQ.removeFirst();
        var close = tQ.removeFirst();
        if(close != '#>') throw 'Expected #>';
        body.writeln(cbBody);
      } else if(t == '<#@') { // <#@, dName, dVal, #>
        if(tQ.length < 3) throw 'Unexpected EOF';
        var dName = tQ.removeFirst();
        String dVal = tQ.removeFirst();
        var close = tQ.removeFirst();
        if(close != '#>') throw 'Expected #>';
        if(dVal.startsWith("'") && dVal.endsWith("'"))
          dVal = dVal.substring(1, dVal.length - 1);
        if(dName == 'param') {
          if(!new RegExp(r'^[a-zA-Z$_][a-zA-Z0-9$_]*$').hasMatch(dVal))
            throw 'Invalid value for param directive';
          params.add(dVal);
        } else if(dName == 'output-name') {
          body.writeln('setOutput(\'${_escape(dVal)}\');');
        } else if(dName == 'import') {
          if(!new RegExp(r'^(\w+:)?(\w/)*\w+\.dart$').hasMatch(dVal))
            throw 'Invalid value for import directive';
          imports.add(_escape(dVal)); // _escape is not really necessary here
        }
      } else if(t == '<#=') { // <#=, expr, #>
        if(tQ.length < 2) throw 'Unexpected EOF';
        var expr = tQ.removeFirst();
        var close = tQ.removeFirst();
        if(close != '#>') throw 'Expected #>';
        body.writeln('write($expr);');
      } else {
        var tEsc = _escape(t);
        if(tEsc.isNotEmpty)
          body.writeln('write(\'$tEsc\');');
      }
    }
    progress = 3;
  }
  
  void compile() {
    if(progress < 3) throw 'Not ready';
    output = new StringBuffer();
    output.writeln('library generatedRuntime;\n');
    
    for(String s in imports) {
      output.writeln('import $s;');
    }
    
    output.writeln('''
import 'dart:isolate';

void main(List<String> args, snd) {
  _output = {};
  currentOutput = new StringBuffer();
  var params = {};
  for(int i = 0; i < args.length; i++) {
    if(i + 1 < args.length) {
      params[args[i]] = args[++i];
    }
  }
''');
    for(String p in params) {
      output.writeln('var $p = params.containsKey($p) ? params[$p] : \'\';');
    }
    var paramString = params.join(', ');
    output.writeln('''
  transform($paramString);
  setOutput('');
  snd.send(_output);
}

Map<String, String> _output;
StringBuffer currentOutput;
String currentOutputName = '';

void write(obj) {
  currentOutput.write(obj);
}

void writeln([obj]) {
  if(obj != null) write(obj);
  write('\\n');
}

void setOutput(name) {
  if(!_output.containsKey(currentOutputName))
    _output[currentOutputName] = '';
  _output[currentOutputName] += currentOutput.toString();
  currentOutput.clear();
  currentOutputName = name;
}''');
    
    output.writeln('void transform($paramString) {');
    output.writeln(body.toString());
    output.writeln('}');
  }
  
  String _escape(String text) {
    text = text.replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    if(text.startsWith('\n')) {
      text = text.substring(1);
    }
    text = text.replaceAll('\n', r'\n')
        .replaceAll('\$', r'\$')
        .replaceAll('\'', '\\\'');
    return text;
  }
}