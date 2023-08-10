import 'package:shorebird_code_push_protocol/src/models/models.dart';
import 'package:test/test.dart';

void main() {
  group(PatchEvent, () {
    group(PatchInstallEvent, () {
      test('can be (de)serialized', () {
        late PatchEvent event;
        event = PatchInstallEvent(
          clientId: 'some-client-id',
          appId: 'some-app-id',
          patchNumber: 2,
          arch: 'arm64',
          platform: ReleasePlatform.android,
          releaseVersion: '1.0.0',
        );
        expect(
          event.toJson(),
          equals(
            PatchEvent.fromJson(event.toJson()).toJson(),
          ),
        );
      });
    });

    group('unrecognized type', () {
      test('throws ArgumentError if type is unrecognized', () {
        expect(
          () => PatchEvent.fromJson(<String, dynamic>{'type': 'foo'}),
          throwsArgumentError,
        );
      });
    });
  });
}