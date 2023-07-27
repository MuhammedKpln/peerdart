import 'package:flutter_test/flutter_test.dart';
import 'package:peerdart/peerdart.dart';
import 'package:peerdart/src/logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("logger", () {
    test("should be disabled by default", () {
      expect(logger.logLevel, LogLevel.Disabled);
    });

    test("should be accept new log level", () {
      final checkedLevels = [];

      logger.setLogFunction((logLevel, message) {
        checkedLevels.add(logLevel);
      });

      logger.logLevel = LogLevel.All;
      expect(logger.logLevel, LogLevel.All);
      logger.log("ew");
      logger.logLevel = LogLevel.Warnings;
      expect(logger.logLevel, LogLevel.Warnings);
      logger.warn("ew");
      logger.logLevel = LogLevel.Errors;
      expect(logger.logLevel, LogLevel.Errors);
      logger.error("ew");
      expect(checkedLevels, containsAll([LogLevel.Warnings, LogLevel.Errors]));
    });

    test("it should accept log function", () {
      final checkedLevels = [];
      const testMessage = "test it";

      logger.setLogFunction((logLevel, message) {
        checkedLevels.add(logLevel);

        expect(message, testMessage);
      });

      logger.logLevel = LogLevel.All;
      expect(logger.logLevel, LogLevel.All);
      logger.log(testMessage);
      logger.logLevel = LogLevel.Warnings;
      expect(logger.logLevel, LogLevel.Warnings);
      logger.warn(testMessage);
      logger.logLevel = LogLevel.Errors;
      expect(logger.logLevel, LogLevel.Errors);
      logger.error(testMessage);
      expect(checkedLevels,
          containsAll([LogLevel.Warnings, LogLevel.Errors, LogLevel.All]));
    });
  });
}
