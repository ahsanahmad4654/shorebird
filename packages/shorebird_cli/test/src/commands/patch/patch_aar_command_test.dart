import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:shorebird_cli/src/archive_analysis/archive_analysis.dart';
import 'package:shorebird_cli/src/auth/auth.dart';
import 'package:shorebird_cli/src/cache.dart' show Cache;
import 'package:shorebird_cli/src/commands/commands.dart';
import 'package:shorebird_cli/src/shorebird_build_mixin.dart';
import 'package:shorebird_cli/src/shorebird_environment.dart';
import 'package:shorebird_cli/src/shorebird_process.dart';
import 'package:shorebird_cli/src/validators/validators.dart';
import 'package:shorebird_code_push_client/shorebird_code_push_client.dart';
import 'package:test/test.dart';

class _FakeBaseRequest extends Fake implements http.BaseRequest {}

class _MockAarDiffer extends Mock implements AarDiffer {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockAuth extends Mock implements Auth {}

class _MockCache extends Mock implements Cache {}

class _MockLogger extends Mock implements Logger {}

class _MockPlatform extends Mock implements Platform {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessResult extends Mock implements ShorebirdProcessResult {}

class _MockHttpClient extends Mock implements http.Client {}

class _MockCodePushClient extends Mock implements CodePushClient {}

class _MockShorebirdFlutterValidator extends Mock
    implements ShorebirdFlutterValidator {}

class _MockShorebirdProcess extends Mock implements ShorebirdProcess {}

class _FakeShorebirdProcess extends Fake implements ShorebirdProcess {}

void main() {
  group(PatchAarCommand, () {
    const flutterRevision = '83305b5088e6fe327fb3334a73ff190828d85713';
    const appId = 'test-app-id';
    const buildNumber = '1.0';
    const versionName = '1.2.3';
    const versionCode = '1';
    const version = '$versionName+$versionCode';
    const arch = 'aarch64';
    const platform = 'android';
    const channelName = 'stable';
    const appDisplayName = 'Test App';
    const appMetadata = AppMetadata(appId: appId, displayName: appDisplayName);
    const patchArtifact = PatchArtifact(
      id: 0,
      patchId: 0,
      arch: arch,
      platform: platform,
      hash: '#',
      size: 42,
      url: 'https://example.com',
    );
    const releaseArtifact = ReleaseArtifact(
      id: 0,
      releaseId: 0,
      arch: arch,
      platform: platform,
      hash: '#',
      size: 42,
      url: 'https://example.com/release.so',
    );
    const aarArtifact = ReleaseArtifact(
      id: 0,
      releaseId: 0,
      arch: arch,
      platform: platform,
      hash: '#',
      size: 42,
      url: 'https://example.com/release.aar',
    );
    const release = Release(
      id: 0,
      appId: appId,
      version: version,
      flutterRevision: flutterRevision,
      displayName: '1.2.3+1',
    );
    const patch = Patch(id: 0, number: 1);
    const channel = Channel(id: 0, appId: appId, name: channelName);
    const noModulePubspecYamlContent = '''
name: example
version: 1.0.0
environment:
  sdk: ">=2.19.0 <3.0.0"
  
flutter:
  assets:
    - shorebird.yaml''';

    const pubspecYamlContent = '''
name: example
version: 1.0.0
environment:
  sdk: ">=2.19.0 <3.0.0"
  
flutter:
  module:
    androidX: true
    androidPackage: com.example.my_flutter_module
    iosBundleIdentifier: com.example.myFlutterModule
  assets:
    - shorebird.yaml''';

    late AarDiffer aarDiffer;
    late ArgResults argResults;
    late Auth auth;
    late Directory shorebirdRoot;
    late Platform environmentPlatform;
    late Progress progress;
    late Logger logger;
    late ShorebirdProcessResult flutterBuildProcessResult;
    late ShorebirdProcessResult flutterRevisionProcessResult;
    late ShorebirdProcessResult patchProcessResult;
    late http.Client httpClient;
    late CodePushClient codePushClient;
    late Cache cache;
    late PatchAarCommand command;
    late Uri? capturedHostedUri;
    late ShorebirdFlutterValidator flutterValidator;
    late ShorebirdProcess shorebirdProcess;

    Directory setUpTempDir({bool includeModule = true}) {
      final tempDir = Directory.systemTemp.createTempSync();
      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync(
        includeModule ? pubspecYamlContent : noModulePubspecYamlContent,
      );
      File(
        p.join(tempDir.path, 'shorebird.yaml'),
      ).writeAsStringSync('app_id: $appId');
      return tempDir;
    }

    void setUpTempArtifacts(Directory dir) {
      final aarDir = p.join(
        'build',
        'host',
        'outputs',
        'repo',
        'com',
        'example',
        'my_flutter_module',
        'flutter_release',
        buildNumber,
      );
      final aarPath = p.join(aarDir, 'flutter_release-$buildNumber.aar');
      for (final archMetadata
          in ShorebirdBuildMixin.allAndroidArchitectures.values) {
        final artifactPath = p.join(
          aarDir,
          'flutter_release-$buildNumber',
          'jni',
          archMetadata.path,
          'libapp.so',
        );
        File(artifactPath).createSync(recursive: true);
      }
      File(aarPath).createSync(recursive: true);
    }

    setUpAll(() {
      registerFallbackValue(_FakeBaseRequest());
      registerFallbackValue(_FakeShorebirdProcess());
    });

    setUp(() {
      aarDiffer = _MockAarDiffer();
      argResults = _MockArgResults();
      auth = _MockAuth();
      shorebirdRoot = Directory.systemTemp.createTempSync();
      environmentPlatform = _MockPlatform();
      progress = _MockProgress();
      logger = _MockLogger();
      flutterBuildProcessResult = _MockProcessResult();
      flutterRevisionProcessResult = _MockProcessResult();
      patchProcessResult = _MockProcessResult();
      httpClient = _MockHttpClient();
      codePushClient = _MockCodePushClient();
      flutterValidator = _MockShorebirdFlutterValidator();
      cache = _MockCache();
      shorebirdProcess = _MockShorebirdProcess();
      command = PatchAarCommand(
        aarDiffer: aarDiffer,
        auth: auth,
        buildCodePushClient: ({
          required http.Client httpClient,
          Uri? hostedUri,
        }) {
          capturedHostedUri = hostedUri;
          return codePushClient;
        },
        cache: cache,
        logger: logger,
        httpClient: httpClient,
        validators: [flutterValidator],
        unzipFn: (_, __) async {},
      )
        ..testArgResults = argResults
        ..testProcess = shorebirdProcess
        ..testEngineConfig = const EngineConfig.empty();

      ShorebirdEnvironment.platform = environmentPlatform;
      when(() => environmentPlatform.script).thenReturn(
        Uri.file(
          p.join(
            shorebirdRoot.path,
            'bin',
            'cache',
            'shorebird.snapshot',
          ),
        ),
      );
      when(
        () => shorebirdProcess.run(
          'flutter',
          any(),
          runInShell: any(named: 'runInShell'),
        ),
      ).thenAnswer((_) async => flutterBuildProcessResult);
      when(
        () => shorebirdProcess.run(
          'git',
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => flutterRevisionProcessResult);
      when(
        () => shorebirdProcess.run(
          any(that: endsWith('patch')),
          any(),
          runInShell: any(named: 'runInShell'),
        ),
      ).thenAnswer((invocation) async {
        final args = invocation.positionalArguments[1] as List<String>;
        final diffPath = args[2];
        File(diffPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('diff');
        return patchProcessResult;
      });

      when(() => aarDiffer.contentDifferences(any(), any())).thenReturn({});
      when(() => argResults.rest).thenReturn([]);
      when(() => argResults['channel']).thenReturn(channelName);
      when(() => argResults['dry-run']).thenReturn(false);
      when(() => argResults['force']).thenReturn(false);
      when(() => argResults['build-number']).thenReturn(buildNumber);
      when(() => argResults['release-version']).thenReturn(version);
      when(() => auth.isAuthenticated).thenReturn(true);
      when(() => auth.client).thenReturn(httpClient);
      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(version);
      when(() => logger.confirm(any())).thenReturn(true);
      when(
        () => flutterBuildProcessResult.exitCode,
      ).thenReturn(ExitCode.success.code);

      when(
        () => flutterRevisionProcessResult.exitCode,
      ).thenReturn(ExitCode.success.code);
      when(
        () => flutterRevisionProcessResult.stdout,
      ).thenReturn(flutterRevision);

      when(() => patchProcessResult.exitCode).thenReturn(ExitCode.success.code);
      when(() => httpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(const Stream.empty(), HttpStatus.ok),
      );
      when(
        () => codePushClient.getApps(),
      ).thenAnswer((_) async => [appMetadata]);
      when(
        () => codePushClient.getChannels(appId: any(named: 'appId')),
      ).thenAnswer((_) async => [channel]);
      when(
        () => codePushClient.getReleases(appId: any(named: 'appId')),
      ).thenAnswer((_) async => [release]);
      when(
        () => codePushClient.getReleaseArtifact(
          releaseId: any(named: 'releaseId'),
          arch: any(named: 'arch'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async => releaseArtifact);
      when(
        () => codePushClient.getReleaseArtifact(
          releaseId: any(named: 'releaseId'),
          arch: 'aar',
          platform: 'android',
        ),
      ).thenAnswer((_) async => aarArtifact);
      when(
        () => codePushClient.createChannel(
          appId: any(named: 'appId'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => channel);
      when(
        () => codePushClient.createPatch(releaseId: any(named: 'releaseId')),
      ).thenAnswer((_) async => patch);
      when(
        () => codePushClient.createPatchArtifact(
          artifactPath: any(named: 'artifactPath'),
          patchId: any(named: 'patchId'),
          arch: any(named: 'arch'),
          platform: any(named: 'platform'),
          hash: any(named: 'hash'),
        ),
      ).thenAnswer((_) async => patchArtifact);
      when(
        () => codePushClient.promotePatch(
          patchId: any(named: 'patchId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});
      when(() => flutterValidator.validate(any())).thenAnswer((_) async => []);
      when(() => cache.updateAll()).thenAnswer((_) async => {});
      when(
        () => cache.getArtifactDirectory(any()),
      ).thenReturn(Directory.systemTemp.createTempSync());
    });

    test('throws config error when shorebird is not initialized', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => logger.err(
          'Shorebird is not initialized. Did you run "shorebird init"?',
        ),
      ).called(1);
      expect(exitCode, ExitCode.config.code);
    });

    test('has a description', () {
      expect(command.description, isNotEmpty);
    });

    test('throws no user error when user is not logged in', () async {
      when(() => auth.isAuthenticated).thenReturn(false);
      final tempDir = setUpTempDir();
      final exitCode = await IOOverrides.runZoned(
        () => command.run(),
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, equals(ExitCode.noUser.code));
    });

    test('exits with 78 if no module entry exists in pubspec.yaml', () async {
      final tempDir = setUpTempDir(includeModule: false);

      final result = await IOOverrides.runZoned(
        () async => command.run(),
        getCurrentDirectory: () => tempDir,
      );

      expect(result, ExitCode.config.code);
    });

    test('exits with code 70 when building fails', () async {
      when(() => flutterBuildProcessResult.exitCode).thenReturn(1);
      when(() => flutterBuildProcessResult.stderr).thenReturn('oops');

      final tempDir = setUpTempDir();
      final exitCode = await IOOverrides.runZoned(
        () async => command.run(),
        getCurrentDirectory: () => tempDir,
      );

      expect(exitCode, equals(ExitCode.software.code));
    });

    test(
        'exits with usage code when '
        'both --dry-run and --force are specified', () async {
      when(() => argResults['dry-run']).thenReturn(true);
      when(() => argResults['force']).thenReturn(true);
      final tempDir = setUpTempDir();
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('throws error when fetching apps fails.', () async {
      const error = 'something went wrong';
      when(() => codePushClient.getApps()).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when app does not exist fails.', () async {
      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(appDisplayName);
      when(() => codePushClient.getApps()).thenAnswer((_) async => []);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => logger.err(
          '''
Could not find app with id: "$appId".
Did you forget to run "shorebird init"?''',
        ),
      ).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('errors when unable to detect flutter revision', () async {
      const error = 'oops';
      when(() => flutterRevisionProcessResult.exitCode).thenReturn(1);
      when(() => flutterRevisionProcessResult.stderr).thenReturn(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, ExitCode.software.code);
      verify(
        () => progress.fail(
          'Exception: Unable to determine flutter revision: $error',
        ),
      ).called(1);
    });

    test(
        'errors when shorebird flutter revision '
        'does not match release revision', () async {
      const otherRevision = 'other-revision';
      when(() => flutterRevisionProcessResult.stdout).thenReturn(otherRevision);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, ExitCode.software.code);
      final shorebirdFlutterPath = ShorebirdEnvironment.flutterDirectory.path;
      verify(
        () => logger.err('''
Flutter revision mismatch.

The release you are trying to patch was built with a different version of Flutter.

Release Flutter Revision: $flutterRevision
Current Flutter Revision: $otherRevision
'''),
      ).called(1);
      verify(
        () => logger.info('''
Either create a new release using:
  ${lightCyan.wrap('shorebird release aar')}

Or downgrade your Flutter version and try again using:
  ${lightCyan.wrap('cd $shorebirdFlutterPath')}
  ${lightCyan.wrap('git checkout ${release.flutterRevision}')}

Shorebird plans to support this automatically, let us know if it's important to you:
https://github.com/shorebirdtech/shorebird/issues/472
'''),
      ).called(1);
    });

    test('throws error when fetching releases fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getReleases(appId: any(named: 'appId')),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when release does not exist.', () async {
      when(
        () => codePushClient.getReleases(appId: any(named: 'appId')),
      ).thenAnswer((_) async => []);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => logger.err(
          '''
Release not found: "$version"

Patches can only be published for existing releases.
Please create a release using "shorebird release aar" and try again.
''',
        ),
      ).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when aar artifact cannot be retrieved', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getReleaseArtifact(
          releaseId: any(named: 'releaseId'),
          arch: 'aar',
          platform: 'android',
        ),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when release artifact cannot be retrieved.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getReleaseArtifact(
          releaseId: any(named: 'releaseId'),
          arch: any(named: 'arch'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when release artifact does not exist.', () async {
      when(
        () => httpClient.send(
          any(
            that: isA<http.Request>().having(
              (req) => req.url.toString(),
              'url',
              endsWith('so'),
            ),
          ),
        ),
      ).thenAnswer(
        (_) async => http.StreamedResponse(
          const Stream.empty(),
          HttpStatus.notFound,
          reasonPhrase: 'Not Found',
        ),
      );
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => progress.fail(any(that: contains('404 Not Found'))),
      ).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when aar fails to download', () async {
      when(
        () => httpClient.send(
          any(
            that: isA<http.Request>().having(
              (req) => req.url.toString(),
              'url',
              endsWith('aar'),
            ),
          ),
        ),
      ).thenAnswer(
        (_) async => http.StreamedResponse(
          const Stream.empty(),
          HttpStatus.internalServerError,
          reasonPhrase: 'Internal Server Error',
        ),
      );

      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );

      expect(exitCode, ExitCode.software.code);
    });

    test('prompts user to continue when asset changes are detected', () async {
      when(() => aarDiffer.contentDifferences(any(), any())).thenReturn(
        {ArchiveDifferences.assets},
      );

      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );

      expect(exitCode, ExitCode.success.code);
      verify(
        () => logger.info(
          any(
            that: contains(
              '''The Android Archive contains asset changes, which will not be included in the patch.''',
            ),
          ),
        ),
      ).called(1);
      verify(() => logger.confirm('Continue anyways?')).called(1);
    });

    test(
      '''does not warn user of asset or code changes if only dart changes are detected''',
      () async {
        when(() => aarDiffer.contentDifferences(any(), any())).thenReturn(
          {ArchiveDifferences.dart},
        );

        final tempDir = setUpTempDir();
        setUpTempArtifacts(tempDir);
        final exitCode = await IOOverrides.runZoned(
          command.run,
          getCurrentDirectory: () => tempDir,
        );

        expect(exitCode, ExitCode.success.code);
        verifyNever(
          () => logger.confirm(
            any(
              that: contains(
                '''The Android Archive contains asset changes, which will not be included in the patch.''',
              ),
            ),
          ),
        );
      },
    );

    test(
      '''exits if user decides to not proceed after being warned of non-dart changes''',
      () async {
        when(() => aarDiffer.contentDifferences(any(), any())).thenReturn(
          {ArchiveDifferences.assets},
        );
        when(
          () => logger.confirm(any(that: contains('Continue anyways?'))),
        ).thenReturn(false);

        final tempDir = setUpTempDir();
        setUpTempArtifacts(tempDir);
        final exitCode = await IOOverrides.runZoned(
          command.run,
          getCurrentDirectory: () => tempDir,
        );

        expect(exitCode, ExitCode.success.code);
        verifyNever(
          () => codePushClient.createPatch(releaseId: any(named: 'releaseId')),
        );
      },
    );

    test('throws error when creating diff fails', () async {
      const error = 'oops something went wrong';
      when(() => patchProcessResult.exitCode).thenReturn(1);
      when(() => patchProcessResult.stderr).thenReturn(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => progress.fail('Exception: Failed to create diff: $error'),
      ).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('does not create patch on --dry-run', () async {
      when(() => argResults['dry-run']).thenReturn(true);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, equals(ExitCode.success.code));
      verifyNever(
        () => codePushClient.createPatch(releaseId: any(named: 'releaseId')),
      );
      verify(() => logger.info('No issues detected.')).called(1);
    });

    test('aborts when user opts out', () async {
      when(() => logger.confirm(any())).thenReturn(false);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('Aborting.')).called(1);
    });

    test('does not prompt on --force', () async {
      when(() => argResults['force']).thenReturn(true);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(exitCode, equals(ExitCode.success.code));
      verifyNever(() => logger.confirm(any()));
      verify(
        () => codePushClient.createPatch(releaseId: any(named: 'releaseId')),
      ).called(1);
    });

    test('throws error when creating patch fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.createPatch(releaseId: any(named: 'releaseId')),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when uploading patch artifact fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.createPatchArtifact(
          artifactPath: any(named: 'artifactPath'),
          patchId: any(named: 'patchId'),
          arch: any(named: 'arch'),
          platform: any(named: 'platform'),
          hash: any(named: 'hash'),
        ),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when fetching channels fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getChannels(appId: any(named: 'appId')),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when creating channel fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getChannels(appId: any(named: 'appId')),
      ).thenAnswer((_) async => []);
      when(
        () => codePushClient.createChannel(
          appId: any(named: 'appId'),
          channel: any(named: 'channel'),
        ),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('throws error when promoting patch fails.', () async {
      const error = 'something went wrong';
      when(
        () => codePushClient.getChannels(appId: any(named: 'appId')),
      ).thenAnswer((_) async => []);
      when(
        () => codePushClient.promotePatch(
          patchId: any(named: 'patchId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenThrow(error);
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => progress.fail(error)).called(1);
      expect(exitCode, ExitCode.software.code);
    });

    test('succeeds when patch is successful', () async {
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(
        () => logger.info(
          any(
            that: contains(
              '''🕹️  Platform: ${lightCyan.wrap(platform)} ${lightCyan.wrap('[arm64 (4 B), arm32 (4 B), x86_64 (4 B)]')}''',
            ),
          ),
        ),
      ).called(1);
      verify(() => logger.success('\n✅ Published Patch!')).called(1);
      expect(exitCode, ExitCode.success.code);
      expect(capturedHostedUri, isNull);
    });

    test('succeeds when patch is successful with flavors', () async {
      const flavor = 'development';
      when(() => argResults['flavor']).thenReturn(flavor);
      final tempDir = setUpTempDir();
      File(
        p.join(tempDir.path, 'shorebird.yaml'),
      ).writeAsStringSync('''
app_id: productionAppId
flavors:
  development: $appId''');
      setUpTempArtifacts(tempDir);
      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      verify(() => logger.success('\n✅ Published Patch!')).called(1);
      expect(exitCode, ExitCode.success.code);
      expect(capturedHostedUri, isNull);
    });

    test('succeeds when patch is successful using custom base_url', () async {
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      const baseUrl = 'https://example.com';
      File(
        p.join(tempDir.path, 'shorebird.yaml'),
      ).writeAsStringSync(
        '''
app_id: $appId
base_url: $baseUrl''',
      );
      await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );
      expect(capturedHostedUri, equals(Uri.parse(baseUrl)));
    });

    test('prints flutter validation warnings', () async {
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      when(() => flutterValidator.validate(any())).thenAnswer(
        (_) async => [
          const ValidationIssue(
            severity: ValidationIssueSeverity.warning,
            message: 'Flutter issue 1',
          ),
          const ValidationIssue(
            severity: ValidationIssueSeverity.warning,
            message: 'Flutter issue 2',
          ),
        ],
      );

      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );

      expect(exitCode, equals(ExitCode.success.code));
      verify(
        () => logger.info(any(that: contains('Flutter issue 1'))),
      ).called(1);
      verify(
        () => logger.info(any(that: contains('Flutter issue 2'))),
      ).called(1);
    });

    test('aborts if validation errors are present', () async {
      final tempDir = setUpTempDir();
      setUpTempArtifacts(tempDir);
      when(() => flutterValidator.validate(any())).thenAnswer(
        (_) async => [
          const ValidationIssue(
            severity: ValidationIssueSeverity.error,
            message: 'There was an issue',
          ),
        ],
      );

      final exitCode = await IOOverrides.runZoned(
        command.run,
        getCurrentDirectory: () => tempDir,
      );

      expect(exitCode, equals(ExitCode.config.code));
      verify(() => logger.err('Aborting due to validation errors.')).called(1);
    });
  });
}