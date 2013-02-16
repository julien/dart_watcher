#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';


void abort([String message = 'bye bye!', int statusCode = 0]) {
  print(message);
  exit(statusCode);
}

class DartFileWatcher {

  File _file;
  DateTime _lastModified;
  Timer _timer;
  String _outputName;
  ProcessOptions _processOptions;

  void _compile() {
    print('Compiling ${_file.name} to ${_outputName}...');

    Future<ProcessResult> processResult = Process.run(
        '/Applications/dart/dart-sdk/bin/dart2js',
        ['-o${_outputName}', '${_file.name}'], _processOptions);

    processResult.then((ProcessResult result) {
      if (result.exitCode != 0) {
        if (result.stdout.length > 0) {
          print('\n${result.stdout}');
        }
        if (result.stderr.length > 0){
          print('\n${result.stderr}');
        }
      } else {
        print('${_file.name} compiled to ${_outputName}');
      }
    });
  }


  void _checkIfModified(Timer timer) {
    _file.lastModified().then((DateTime dateTime) {
      if (_lastModified.millisecondsSinceEpoch != dateTime.millisecondsSinceEpoch) {
        print('File: ${_file.name} was updated...');

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
      abort('** You can only use me with ".dart" files **');
    }
  }
}



onError(AsyncError error) {
  abort('** ERROR **\n${error.toString()}', 1);
}

void initialize(Directory directory) {
  print('Checking: ${directory.path} for dart files...');

  DirectoryLister lister = directory.list();
  int found = 0;

  lister.onFile = (String file) {
    if (file.endsWith('.dart')) {
      print('Found: $file');
      ++found;
      new DartFileWatcher(new File.fromPath(new Path(file)));
    }
  };

  lister.onDone = (bool completed) {
    if (completed) {
      if (found == 0) {
        print('No .dart files found ... will recheck in 5 seconds.');
        new Timer(5000, (Timer timer) => initialize(directory));
      }
    }
  };

  lister.onError = (DirectoryIOException exception) {
    abort('** ERROR **\n${exception.message}', 1);
  };
}


Future<dynamic> checkDirectory(Directory directory) {
  Completer completer = new Completer();

  directory.exists().then((bool exists) {
    if (exists) {
      completer.complete(directory);
    } else {
      completer.complete(exists);
    }
  }, onError: onError);
  return completer.future;
}

void main() {

  Options options = new Options();
  String path;

  if (options.arguments.length > 0) {
    path = options.arguments[0];
  } else {
    path = new Directory.current().path;
  }

  checkDirectory(new Directory(path)).then((dynamic value) {
    if (value is Directory) {
      initialize(value);
    }
  }, onError: onError);

}
