import 'dart:io';

import 'package:flutter/foundation.dart';

bool get isWeb => kIsWeb;

bool get isAndroid => Platform.isAndroid;

bool get isIOS => Platform.isIOS;

bool get isMobile => !isWeb && (isAndroid || isIOS);
