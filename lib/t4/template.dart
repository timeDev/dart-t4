part of t4;

class TextTemplate {
  final String source;
  Map<String, String> params;
  String compiledSource;
  
  TextTemplate(String source, [Map<String, String> params])
      : source = source
  {
    if(params == null) params = {};
    this.params = params;
  }
  
  void addParameter(String name, String value) {
    params[name] = value;
  }
  
  String compile() {
    var engine = new _T4Engine(this);
    engine.tokenize1();
    engine.tokenize2();
    engine.preProcess();
    engine.compile();
    return compiledSource = engine.output.toString();
  }
  
  Future<Map<String, String>> transform() {
    if(compiledSource == null) compile();
    var name = new Random().nextInt(9999).toString();
    var path = Directory.systemTemp.path + '/DT4_temp$name.dart';
    var tempFile = new File(path)..create();
    tempFile.writeAsStringSync(compiledSource);
    var args = [];
    for(var k in params.keys) {
      args.add(k);
      args.add(params[k]);
    }
    var uri = Uri.parse(tempFile.path);
    var receiver = new ReceivePort();
    var result = Isolate.spawnUri(uri, args, receiver.sendPort).then((T) {
      tempFile.delete();
      return T;
    }).then((iso) => receiver.first.then((T) { receiver.close(); return T; }));
    return result;
  }
  
  Future<Map<String, String>> _extractOutput(Isolate isolate) {
    //sleep(new Duration(milliseconds:20));
    var receiver = new ReceivePort();
    print('Sending message..');
    isolate.controlPort.send(receiver.sendPort);
    return receiver.first.then((T) { receiver.close(); return T; });
  }
}