import 'package:dart_t4/t4.dart';
import 'dart:io';
import 'dart:async';

void main(List<String> args) {
  var redirects = {};
  var params = {};
  var sources = [];
  var outputdir = Directory.current;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--redirect' || args[i] == '-r') {
      if (i + 2 >= args.length) break;
      var key = args[++i];
      var value = args[++i];
      redirects[key] = value;
    } else if (args[i] == '--param' || args[i] == '-p') {
      if (i + 2 >= args.length) break;
      var key = args[++i];
      var value = args[++i];
      params[key] = value;
    } else if (args[i] == '--ouput' || args[i] == '-o') {
      if (i + 1 >= args.length) break;
      outputdir = new Directory(args[++i]);
    } else {
      sources.add(args[i]);
    }
  }
  if (sources.isEmpty) {
    print('No sources specified');
    return;
  }
  outputdir = outputdir.absolute;
  var outputpath = outputdir.path.endsWith('/') || outputdir.path.endsWith('\\') ?
      outputdir.path : outputdir.path + '/';
  var files = [];
  for (var filename in sources) {
    var file = new File(filename);
    if (file.existsSync()) {
      files.add(file);
    } else {
      print('File "$filename" not found');
    }
  }
  var output = {};
  var futures = [];
  for (File file in files) {
    var source = file.readAsStringSync();
    var template = new TextTemplate(source, params);
    futures.add(template.transform().then((curOutput) {
      for (var key in curOutput) {
        if (!output.containsKey(key)) output[key] = '';
        output[key] += curOutput[key];
      }
    }));
  }
  if (!outputdir.existsSync()) outputdir.createSync(recursive: true);
  Future.wait(futures).then((_) {
    for (var key in redirects.keys.where(output.containsKey)) {
      output[redirects[key]] = output[key];
      output.remove(key);
    }
    for (var key in output) {
      var file = new File(outputpath + key);
      file.createSync();
      file.openWrite().write(output[key]);
    }
    print('Done');
  });
}
