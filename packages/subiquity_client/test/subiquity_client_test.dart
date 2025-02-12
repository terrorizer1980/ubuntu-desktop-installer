import 'package:test/test.dart';
import 'package:subiquity_client/subiquity_client.dart';
import 'package:subiquity_client/subiquity_server.dart';
import 'package:subiquity_client/src/types.dart';

void main() {
  final _testServer = SubiquityServer();
  final _client = SubiquityClient();
  var _socketPath;

  setUpAll(() async {
    _socketPath =
        await _testServer.start(ServerMode.DRY_RUN, 'examples/simple.json');
    _client.open(_socketPath);
  });

  tearDownAll(() async {
    _client.close();
    await _testServer.stop();
  });

  test('locale', () async {
    await _client.switchLanguage('en_US');
    expect(await _client.locale(), 'en_US');
  });

  test('keyboard', () async {
    var kb = await _client.keyboard();
    expect(kb.setting?.layout, 'us');
    expect(kb.setting?.variant, '');
    expect(kb.setting?.toggle, null);
    expect(kb.layouts, isNotEmpty);
  });

  test('guided storage', () async {
    var gs = await _client.getGuidedStorage(0, true);
    expect(gs.disks, isNotEmpty);
    expect(gs.disks?[0].size, isNot(0));

    var gc = GuidedChoice(
      diskId: 'invalid',
      useLvm: false,
      password: '',
    );

    // TODO: Re-enable once we figure out why _client.send() sometimes hangs in setGuidedStorage()
    // try {
    //   await _client.setGuidedStorage(gc); // should throw
    //   // ignore: avoid_catches_without_on_clauses
    // } catch (e) {
    //   expect(
    //       e,
    //       startsWith(
    //           'setGuidedStorage({"disk_id":"invalid","use_lvm":false,"password":""}) returned error 500'));
    // }

    gc = GuidedChoice(
      diskId: gs.disks?[0].id,
      useLvm: false,
      password: '',
    );

    var sr = await _client.setGuidedStorage(gc);
    expect(sr.status, ProbeStatus.DONE);
  });

  test('proxy', () async {
    expect(await _client.proxy(), '');
  });

  test('mirror', () async {
    expect(await _client.mirror(), endsWith('archive.ubuntu.com/ubuntu'));
  });

  test('identity', () async {
    var id = await _client.identity();
    expect(id.realname, '');
    expect(id.username, '');
    expect(id.cryptedPassword, '');
    expect(id.hostname, '');
  });

  test('ssh', () async {
    var ssh = await _client.ssh();
    expect(ssh.installServer, false);
    expect(ssh.allowPw, true);
    expect(ssh.authorizedKeys, []);
  });

  test('status', () async {
    var status = await _client.status();
    expect(status.state, ApplicationState.WAITING);
    expect(status.confirmingTty, '');
    expect(status.cloudInitOk, true);
    expect(status.interactive, true);
    expect(status.echoSyslogId, startsWith('subiquity_echo.'));
    expect(status.logSyslogId, startsWith('subiquity_log.'));
    expect(status.eventSyslogId, startsWith('subiquity_event.'));
  });

  test('markConfigured', () async {
    await _client.markConfigured(['keyboard']);
  });

  test('confirm', () async {
    await _client.confirm('1');
  });
}
