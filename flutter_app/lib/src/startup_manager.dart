import 'dart:io';

class StartupState {
  const StartupState({
    required this.available,
    required this.launchApp,
    required this.launchAppHidden,
    required this.message,
  });

  final bool available;
  final bool launchApp;
  final bool launchAppHidden;
  final String message;
}

class StartupManager {
  Future<StartupState> load() async => const StartupState(
    available: false,
    launchApp: false,
    launchAppHidden: false,
    message: 'Startup settings are only available on Windows.',
  );

  Future<void> setLaunchApp(bool enabled, {bool hidden = false}) async {
    throw UnsupportedError('Startup settings are only available on Windows.');
  }

}

class WindowsStartupManager extends StartupManager {
  WindowsStartupManager({
    this.startupDirectory,
    this.executableFile,
  });

  static const _appShortcutName = 'What Do You Do.lnk';

  final Directory? startupDirectory;
  final File? executableFile;

  @override
  Future<StartupState> load() async {
    if (!Platform.isWindows) {
      return super.load();
    }

    final startupDir = _startupDir();
    final appShortcut = File('${startupDir.path}\\$_appShortcutName');

    return StartupState(
      available: true,
      launchApp: await appShortcut.exists(),
      launchAppHidden:
        await appShortcut.exists() && await _shortcutUsesHiddenMode(),
      message: 'The app starts its native collector inside the same process.',
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
