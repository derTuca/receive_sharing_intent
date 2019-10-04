import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class ReceiveSharingIntent {
  static const MethodChannel _mChannel =
      const MethodChannel('receive_sharing_intent/messages');

  static const EventChannel _eChannelMedia =
      const EventChannel("receive_sharing_intent/events-media");
  static const EventChannel _eChannelText =
      const EventChannel("receive_sharing_intent/events-text");
  static const EventChannel _eChannelUrl =
      const EventChannel("receive_sharing_intent/events-url");

  static Stream<List<SharedMediaFile>> _streamMedia;
  static Stream<String> _streamText;
  static Stream<SharedUrl> _streamUrl;

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored media uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  ///
  /// NOTE. The returned media on iOS (iOS ONLY) is already copied to a temp folder.
  /// So, you need to delete the file after you finish using it
  static Future<List<SharedMediaFile>> getInitialMedia() async {
    final String json = await _mChannel.invokeMethod('getInitialMedia');
    if (json == null) return null;
    final encoded = jsonDecode(json);
    return encoded
        .map<SharedMediaFile>((file) => SharedMediaFile.fromJson(file))
        .toList();
  }

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored link (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  static Future<String> getInitialText() async {
    return await _mChannel.invokeMethod('getInitialText');
  }

  /// A convenience method that returns the initially stored link
  /// as a new [Uri] object.
  ///
  /// If the link is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  static Future<Uri> getInitialTextAsUri() async {
    final String data = await getInitialText();
    if (data == null) return null;
    return Uri.parse(data);
  }

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored media uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  ///
  /// NOTE. The returned media on iOS (iOS ONLY) is already copied to a temp folder.
  /// So, you need to delete the file after you finish using it
  static Future<SharedUrl> getInitialUrl() async {
    final String json = await _mChannel.invokeMethod('getInitialUrl');
    if (json == null) return null;
    final encoded = jsonDecode(json);
    return SharedUrl.fromJson(encoded);
  }

  /// Sets up a broadcast stream for receiving incoming media share change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([List]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialMedia` instead.
  static Stream<List<SharedMediaFile>> getMediaStream() {
    if (_streamMedia == null) {
      final stream =
          _eChannelMedia.receiveBroadcastStream("media").cast<String>();
      _streamMedia = stream.transform<List<SharedMediaFile>>(
        new StreamTransformer<String, List<SharedMediaFile>>.fromHandlers(
          handleData: (String data, EventSink<List<SharedMediaFile>> sink) {
            if (data == null) {
              sink.add(null);
            } else {
              final encoded = jsonDecode(data);
              sink.add(encoded
                  .map<SharedMediaFile>(
                      (file) => SharedMediaFile.fromJson(file))
                  .toList());
            }
          },
        ),
      );
    }
    return _streamMedia;
  }

  /// Sets up a broadcast stream for receiving incoming link change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([String]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialText` instead.
  static Stream<String> getTextStream() {
    if (_streamText == null) {
      _streamText = _eChannelText.receiveBroadcastStream("text").cast<String>();
    }
    return _streamText;
  }

  /// A convenience transformation of the stream to a `Stream<Uri>`.
  ///
  /// If the value is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  ///
  /// Refer to `getTextStream` about error/exception details.
  ///
  /// If the app was started by a share intent or user activity the stream will
  /// not emit that initial uri - query either the `getInitialTextAsUri` instead.
  static Stream<Uri> getTextStreamAsUri() {
    return getTextStream().transform<Uri>(
      new StreamTransformer<String, Uri>.fromHandlers(
        handleData: (String data, EventSink<Uri> sink) {
          if (data == null) {
            sink.add(null);
          } else {
            sink.add(Uri.parse(data));
          }
        },
      ),
    );
  }

  /// Sets up a broadcast stream for receiving incoming media share change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([List]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialMedia` instead.
  static Stream<SharedUrl> getUrlStream() {
    if (_streamUrl == null) {
      final stream = _eChannelUrl.receiveBroadcastStream("url").cast<String>();
      _streamUrl = stream.transform<SharedUrl>(
        new StreamTransformer<String, SharedUrl>.fromHandlers(
          handleData: (String data, EventSink<SharedUrl> sink) {
            if (data == null) {
              sink.add(null);
            } else {
              final encoded = jsonDecode(data);
              sink.add(SharedUrl.fromJson(encoded));
            }
          },
        ),
      );
    }
    return _streamUrl;
  }

  /// Call this method if you already consumed the callback
  /// and don't want the same callback again
  static void reset() {
    _mChannel.invokeMethod('reset').then((_) {});
  }
}

class SharedMediaFile {
  /// Image or Video path.
  /// NOTE. for iOS only the file is always copied
  final String path;

  /// Video thumbnail
  final String thumbnail;

  /// Video duration in milliseconds
  final int duration;

  /// Whether its a video or image
  final SharedMediaType type;

  SharedMediaFile(this.path, this.thumbnail, this.duration, this.type);

  SharedMediaFile.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        thumbnail = json['thumbnail'],
        duration = json['duration'],
        type = SharedMediaType.values[json['type']];
}

class SharedUrl {
  /// URI of the shared url
  final String url;

  /// Path to the site screenshot
  final String mediaPath;

  SharedUrl(this.url, this.mediaPath);

  SharedUrl.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        mediaPath = json['mediaPath'];
}

enum SharedMediaType { IMAGE, VIDEO }
