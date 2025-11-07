import 'dart:io';

bool isMobile() => Platform.isIOS || Platform.isAndroid;
bool isDesktop() => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
