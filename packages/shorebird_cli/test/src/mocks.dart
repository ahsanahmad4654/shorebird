import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:shorebird_cli/src/adb.dart';
import 'package:shorebird_cli/src/android_sdk.dart';
import 'package:shorebird_cli/src/android_studio.dart';
import 'package:shorebird_cli/src/archive_analysis/archive_analysis.dart';
import 'package:shorebird_cli/src/archive_analysis/archive_differ.dart';
import 'package:shorebird_cli/src/auth/auth.dart';
import 'package:shorebird_cli/src/bundletool.dart';
import 'package:shorebird_cli/src/cache.dart' show Cache;
import 'package:shorebird_cli/src/code_push_client_wrapper.dart';
import 'package:shorebird_cli/src/config/config.dart';
import 'package:shorebird_cli/src/doctor.dart';
import 'package:shorebird_cli/src/git.dart';
import 'package:shorebird_cli/src/gradlew.dart';
import 'package:shorebird_cli/src/ios_deploy.dart';
import 'package:shorebird_cli/src/java.dart';
import 'package:shorebird_cli/src/patch_diff_checker.dart';
import 'package:shorebird_cli/src/process.dart';
import 'package:shorebird_cli/src/shorebird_env.dart';
import 'package:shorebird_cli/src/shorebird_flutter.dart';
import 'package:shorebird_cli/src/shorebird_validator.dart';
import 'package:shorebird_cli/src/shorebird_version.dart';
import 'package:shorebird_cli/src/validators/validators.dart';
import 'package:shorebird_cli/src/xcodebuild.dart';
import 'package:shorebird_code_push_client/shorebird_code_push_client.dart';

class MockAccessCredentials extends Mock implements AccessCredentials {}

class MockAdb extends Mock implements Adb {}

class MockAndroidArchiveDiffer extends Mock implements AndroidArchiveDiffer {}

class MockAndroidSdk extends Mock implements AndroidSdk {}

class MockAndroidStudio extends Mock implements AndroidStudio {}

class MockAppMetadata extends Mock implements AppMetadata {}

class MockArchiveDiffer extends Mock implements ArchiveDiffer {}

class MockArgResults extends Mock implements ArgResults {}

class MockAuth extends Mock implements Auth {}

class MockBundleTool extends Mock implements Bundletool {}

class MockCache extends Mock implements Cache {}

class MockCodePushClient extends Mock implements CodePushClient {}

class MockCodePushClientWrapper extends Mock implements CodePushClientWrapper {}

class MockDoctor extends Mock implements Doctor {}

class MockFile extends Mock implements File {}

class MockFileSetDiff extends Mock implements FileSetDiff {}

class MockGit extends Mock implements Git {}

class MockGradlew extends Mock implements Gradlew {}

class MockHttpClient extends Mock implements http.Client {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockIoHttpClient extends Mock implements HttpClient {}

class MockIOSDeploy extends Mock implements IOSDeploy {}

class MockIOSink extends Mock implements IOSink {}

class MockIosArchiveDiffer extends Mock implements IosArchiveDiffer {}

class MockJava extends Mock implements Java {}

class MockLogger extends Mock implements Logger {}

class MockPatchDiffChecker extends Mock implements PatchDiffChecker {}

class MockPlatform extends Mock implements Platform {}

class MockProcessResult extends Mock implements ShorebirdProcessResult {}

class MockProcessSignal extends Mock implements ProcessSignal {}

class MockProcessWrapper extends Mock implements ProcessWrapper {}

class MockProcess extends Mock implements Process {}

class MockProgress extends Mock implements Progress {}

class MockRelease extends Mock implements Release {}

class MockReleaseArtifact extends Mock implements ReleaseArtifact {}

class MockShorebirdEnv extends Mock implements ShorebirdEnv {}

class MockShorebirdFlutter extends Mock implements ShorebirdFlutter {}

class MockShorebirdFlutterValidator extends Mock
    implements ShorebirdFlutterValidator {}

class MockShorebirdProcess extends Mock implements ShorebirdProcess {}

class MockShorebirdProcessResult extends Mock
    implements ShorebirdProcessResult {}

class MockShorebirdValidator extends Mock implements ShorebirdValidator {}

class MockShorebirdVersion extends Mock implements ShorebirdVersion {}

class MockShorebirdYaml extends Mock implements ShorebirdYaml {}

class MockValidator extends Mock implements Validator {}

class MockXcodeBuild extends Mock implements XcodeBuild {}
