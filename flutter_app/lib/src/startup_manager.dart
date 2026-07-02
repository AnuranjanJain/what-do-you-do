import 'dart:io';

class StartupState {
  const StartupState({
    required this.available,
    required this.collectorAvailable,
    required this.launchApp,
    required this.launchAppHidden,
    required this.launchCollector,
    required this.message,
  });

  final bool available;
  final bool collectorAvailable;
  final bool launchApp;
  final bool launchAppHidden;
  final bool launchCollector;
  final String message;
}

class StartupManager {
  Future<StartupState> load() async => const StartupState(
    available: false,
    collectorAvailable: false,
    launchApp: false,
    launchAppHidden: false,
    launchCollector: false,
    message: 'Startup settings are only available on Windows.',
  );

  Future<void> setLaunchApp(bool enabled, {bool hidden = false}) async {
    throw UnsupportedError('Startup settings are only available on Windows.');
  }

  Future<void> setLaunchCollector(bool enabled) async {
    throw UnsupportedError('Startup settings are only available on Windows.');
  }
}

class WindowsStartupManager extends StartupManager {
  WindowsStartupManager({
    this.startupDirectory,
    this.executableFile,
    this.collectorLauncherFile,
  });

  static const _appShortcutName = 'What Do You Do.lnk';
  static const _collectorShortcutName = 'What Do You Do Collector.lnk';

  final Directory? startupDirectory;
  final File? executableFile;
  final File? collectorLauncherFile;

  @override
  Future<StartupState> load() async {
    if (!Platform.isWindows) {
      return super.load();
    }

    final startupDir = _startupDir();
    final appShortcut = File('${startupDir.path}\\$_appShortcutName');
    final collectorShortcut = File(
      '${startupDir.path}\\$_collectorShortcutName',
    );
    final collectorLauncher = _collectorLauncher();
    final collectorAvailable = await collectorLauncher.exists();

    return StartupState(
      available: true,
      collectorAvailable: collectorAvailable,
      launchApp: await appShortcut.exists(),
      launchAppHidden:
          await appShortcut.exists() && await _shortcutUsesHiddenMode(),
      launchCollector: await collectorShortcut.exists(),
      message: collectorAvailable
          ? 'Startup services can launch the app and local collector.'
          : 'Install the app to enable the packaged collector startup service.',
    );
  }

  @override
  Future<void> setLaunchApp(bool enabled, {bool hidden = false}) async {
    final startupDir = _startupDir();
    final shortcutPath = '${startupDir.path}\\$_appShortcutName';
    if (!enabled) {
      await File(shortcutPath).deleteIfExists();
      return;
    }

    await startupDir.create(recursive: true);
    final executable = _executable();
    await _createShortcut(
      shortcutPath: shortcutPath,
      targetPath: executable.path,
      arguments: hidden ? '--hidden' : '',
      workingDirectory: executable.parent.path,
      description: 'Launch What Do You Do at sign-in',
    );
  }

  @override
  Future<void> setLaunchCollector(bool enabled) async {
    final startupDir = _startupDir();
    final shortcutPath = '${startupDir.path}\\$_collectorShortcutName';
    if (!enabled) {
      await File(shortcutPath).deleteIfExists();
      return;
    }

    final launcher = _collectorLauncher();
    if (!await launcher.exists()) {
      throw StateError('Packaged collector launcher was not found.');
    }

    await startupDir.create(recursive: true);
    await _createShortcut(
      shortcutPath: shortcutPath,
      targetPath: 'powershell.exe',
      arguments:
          '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "${launcher.path}"',
      workingDirectory: launcher.parent.path,
      description: 'Start the What Do You Do local collector at sign-in',
    );
  }

  Directory _startupDir() {
    if (startupDirectory case final directory?) return directory;
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) {
      throw StateError('APPDATA is not available.');
    }
    return Directory(
      '$appData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup',
    );
  }

  File _executable() => executableFile ?? File(Platform.resolvedExecutable);

  File _collectorLauncher() {
    if (collectorLauncherFile case final file?) return file;
    return File('${_executable().parent.path}\\start-collector.ps1');
  }

  Future<bool> _shortcutUsesHiddenMode() async {
    final startupDir = _startupDir();
    final shortcutPath = '${startupDir.path}\\$_appShortcutName';
    final script =
        '''
\$shell = New-Object -ComObject WScript.Shell
\$shortcut = \$shell.CreateShortcut('${shortcutPath.replaceAll("'", "''")}')
\$shortcut.Arguments
''';

    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);

    if (result.exitCode != 0) return false;
    return result.stdout.toString().contains('--hidden');
  }

  Future<void> _createShortcut({
    required String shortcutPath,
    required String targetPath,
    required String arguments,
    required String workingDirectory,
    required String description,
  }) async {
    final shortcut = _psString(shortcutPath);
    final target = _psString(targetPath);
    final args = _psString(arguments);
    final workingDir = _psString(workingDirectory);
    final shortcutDescription = _psString(description);
    final script =
        '''
\$shell = New-Object -ComObject WScript.Shell
\$shortcut = \$shell.CreateShortcut($shortcut)
\$shortcut.TargetPath = $target
\$shortcut.Arguments = $args
\$shortcut.WorkingDirectory = $workingDir
\$shortcut.Description = $shortcutDescription
\$shortcut.Save()
''';

    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);

    if (result.exitCode != 0) {
      throw StateError('Unable to create startup shortcut: ${result.stderr}');
    }
  }

  String _psString(String value) => "'${value.replaceAll("'", "''")}'";
}

extension on File {
  Future<void> deleteIfExists() async {
    try {
      await delete();
    } on FileSystemException catch (error) {
      if (error.osError?.errorCode != 2) rethrow;
    }
  }
}
