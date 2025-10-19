import 'package:classroom/core/services/log_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _log = LogService();

Future<void> loadEnv() async {
  await dotenv.load(fileName: ".env");
  _log.info('Load app succeed.');
}
