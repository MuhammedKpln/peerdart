import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdart/peerdart.dart';

class MTrack extends MediaStreamTrack {
  @override
  bool enabled = true;

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  // TODO: implement id
  String? get id => "1";

  @override
  // TODO: implement kind
  String? get kind => "video";

  @override
  // TODO: implement label
  String? get label => "ss";

  @override
  // TODO: implement muted
  bool? get muted => false;

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }
}

class s extends MediaStream {
  s() : super("1", "1");

  @override
  // TODO: implement active
  bool? get active => throw UnimplementedError();

  @override
  Future<void> addTrack(MediaStreamTrack track, {bool addToNative = true}) {
    // TODO: implement addTrack
    throw UnimplementedError();
  }

  @override
  MediaStream clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  List<MediaStreamTrack> getAudioTracks() {
    return [MTrack()];
  }

  @override
  Future<void> getMediaTracks() {
    // TODO: implement getMediaTracks
    throw UnimplementedError();
  }

  @override
  List<MediaStreamTrack> getTracks() {
    return [MTrack()];
  }

  @override
  List<MediaStreamTrack> getVideoTracks() {
    return [MTrack()];
  }

  @override
  Future<void> removeTrack(MediaStreamTrack track,
      {bool removeFromNative = true}) {
    // TODO: implement removeTrack
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Peer", () {
    test("should contains id and key", () async {
      final peer = Peer(id: "1", options: PeerOptions(key: "anotherKey"));

      expect(peer.id, "1");
      expect(peer.options.key, "anotherKey");

      peer.dispose();
    });

    // test("Peer#1 should have id #1", () async {
    //   final peer1 =
    //       Peer(id: "1", options: PeerOptions(host: "127.0.01", port: 9000));
    //   expect(peer1.open, false);

    //   final mediaStream = s();

    //   final mediaConnection = peer1.call("2", mediaStream);

    //   expect(mediaConnection.connectionId, isA<String>());
    //   expect(mediaConnection.type, ConnectionType.Media);
    //   expect(mediaConnection.peer, "2");

    //   peer1.once("open").then((id) {
    //     expect(id, "1");
    //     expect(peer1.disconnected, false);
    //     expect(peer1.destroyed, false);
    //     expect(peer1.open, true);

    //     peer1.dispose();

    //     expect(peer1.disconnected, true);
    //     expect(peer1.destroyed, true);
    //     expect(peer1.open, false);
    //   });
    // });

    test("connect => disconnect => reconnect => destroy", () {
      final peer1 =
          Peer(id: "1", options: PeerOptions(host: "127.0.01", port: 9000));

      peer1.once("open").then((value) {
        expect(peer1.open, true);

        peer1.once("disconnected").then((value) {
          expect(peer1.disconnected, true);
          expect(peer1.destroyed, false);
          expect(peer1.open, false);
        });

        peer1.once("open").then((id) {
          expect(id, "1");
          expect(peer1.disconnected, false);
          expect(peer1.destroyed, false);
          expect(peer1.open, true);

          peer1.once("disconnected").then((value) {
            expect(peer1.disconnected, true);
            expect(peer1.destroyed, false);
            expect(peer1.open, false);

            peer1.once("close").then((value) {
              expect(peer1.disconnected, true);
              expect(peer1.destroyed, true);
              expect(peer1.open, false);
            });
          });

          peer1.dispose();
        });

        peer1.reconnect();
      });
    });

    test("disconnect peer if no id and no connection", () {
      final peer1 = Peer(options: PeerOptions(host: "127.0.01", port: 9000));

      peer1.once("error").then((value) {
        peer1.once("close").then((value) {
          expect(peer1.disconnected, true);
          expect(peer1.destroyed, true);
          expect(peer1.open, false);
        });
      });
    });
  });
}
