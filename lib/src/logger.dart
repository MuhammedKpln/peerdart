import 'enums.dart';

const LOG_PREFIX = 'PeerDart: ';

/*
Prints log messages depending on the debug level passed in. Defaults to 0.
0  Prints no logs.
1  Prints only errors.
2  Prints errors and warnings.
3  Prints all logs.
*/

class Logger {
  var logLevel = LogLevel.Disabled;

  log(dynamic message) {
    if (logLevel == LogLevel.All) {
      _print(LogLevel.All, message);
    }
  }

  warn(dynamic message) {
    if (logLevel == LogLevel.Warnings) {
      _print(LogLevel.Warnings, message);
    }
  }

  error(dynamic message) {
    if (logLevel == LogLevel.Errors) {
      _print(LogLevel.Errors, message);
    }
  }

  setLogFunction(Function fn) {
    _print = fn;
  }

  Function _print = (LogLevel logLevel, dynamic message) {
    var msg = '$LOG_PREFIX ${message.toString()}';

    if (logLevel == LogLevel.All) {
      print(msg);
    } else if (logLevel == LogLevel.Warnings) {
      print("WARNING $msg");
    } else if (logLevel == LogLevel.Errors) {
      print("ERROR $msg");
    }
  };
}

final logger = Logger();
