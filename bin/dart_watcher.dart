#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';

Directory watchedDir;

class DartFileWatcher {
  File _file;
  DateTime _lastModified;
  Timer _timer;
  String _outputName;

  ProcessOptions _processOptions;

  void _compile() {

    print('Compiling to JavaScript...');

    Future<ProcessResult> processResult = Process.run(
        '/Applications/dart/dart-sdk/bin/dart2js',
        ['-o${_outputName}', '${_file.name}'],
        _processOptions);

    processResult.then((ProcessResult result) {
      print('Exit code: ${result.exitCode}');

      // if (result.stdout.length > 0){
      //  print('Output:\n${result.stdout}');
      // }

      // if (result.stderr.length > 0){
      //   print('Error:\n${result.stderr}');
      // }
    });
  }


  void _checkIfModified(Timer timer) {
    _file.lastModified().then((DateTime dateTime) {
      if (_lastModified.millisecondsSinceEpoch != dateTime.millisecondsSinceEpoch) {
        print('File was updated...\n${_file.toString()}');
        _lastModified = dateTime;
        _compile();
      }
    });
  }

  DartFileWatcher(File this._file) {

    if (_file.name.endsWith('.dart')) {
      _outputName = _file.name.replaceAll('.dart', '.js');

      _file.lastModified().then((DateTime value) {
        _lastModified = value;
        _timer = new Timer.repeating(1000, _checkIfModified);
      });

    } else {
      print('** You can only use me with ".dart" files **');
    }
  }
}


void main() {
  Options options = new Options();
  List<String> arguments = options.arguments;


  watchedDir = new Directory.current();
  print('Watching ${watchedDir.path} for file changes...');


  DirectoryLister lister = watchedDir.list();

  lister.onFile = (String file) {
    if (file.endsWith('.dart')) {
      DartFileWatcher fw = new DartFileWatcher(
          new File.fromPath(new Path(file)));
    }
  };
  lister.onError = (DirectoryIOException exception) {
    print('Error: ${exception.message}');
    exit(0);
  };
}
