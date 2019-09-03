import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Communicates the current state of the audio player.
enum AudioPlayerState {
  /// Player is stopped. No file is loaded to the player. Calling [resume] or
  /// [pause] will result in exception.
  STOPPED,
  /// Currently playing a file. The user can [pause], [resume] or [stop] the
  /// playback.
  PLAYING,
  /// Paused. The user can [resume] the playback without providing the URL.
  PAUSED,
  /// The playback has been completed. This state is the same as [STOPPED],
  /// however we differentiate it because some clients might want to know when
  /// the playback is done versus when the user has stopped the playback.
  COMPLETED,
}

enum PlayerState {
  RELEASED,
  STOPPED,
  BUFFERING,
  PLAYING,
  PAUSED,
  COMPLETED,
}

enum PlayerMode {
  FOREGROUND,
  BACKGROUND,
}

enum Result {
  SUCCESS,
  FAIL,
  ERROR,
}

class AudioPlayer {
  static const MethodChannel _channel =
      const MethodChannel('mb_exo_player');

  static bool logEnabled = false;
  static final players = Map<String, AudioPlayer>();
  static final playerId = '123456';

  static const PlayerStateMap = {
    -1: PlayerState.RELEASED,
    0: PlayerState.STOPPED,
    1: PlayerState.BUFFERING,
    2: PlayerState.PLAYING,
    3: PlayerState.PAUSED,
    4: PlayerState.COMPLETED,
  };

  static const ResultMap = {
    0: Result.ERROR,
    1: Result.FAIL,
    2: Result.SUCCESS,
  };

  PlayerState _playerState;

  PlayerState get playerState => _playerState;

  final StreamController<PlayerState> _playerStateController =
  StreamController<PlayerState>.broadcast();

  final StreamController<Duration> _positionController =
  StreamController<Duration>.broadcast();

  final StreamController<Duration> _durationController =
  StreamController<Duration>.broadcast();

  final StreamController<void> _completionController =
  StreamController<void>.broadcast();

  final StreamController<String> _errorController =
  StreamController<String>.broadcast();

  final StreamController<int> _currentPlayingIndexController =
  StreamController<int>.broadcast();

  /// Stream of changes on player playerState.
  ///
  /// Events are sent every time the state of the audioplayer is changed
  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 200 milliseconds. Will continuously update the
  /// position of the playback if the status is [AudioPlayerState.PLAYING].
  ///
  /// You can use it on a progress bar, for instance.
  Stream<Duration> get onAudioPositionChanged => _positionController.stream;

  /// Stream of changes on audio duration.
  ///
  /// An event is going to be sent as soon as the audio duration is available
  /// (it might take a while to download or buffer it).
  Stream<Duration> get onDurationChanged => _durationController.stream;

  /// Stream of player completions.
  ///
  /// Events are sent every time an audio is finished, therefore no event is
  /// sent when an audio is paused or stopped.
  ///
  /// [ReleaseMode.LOOP] also sends events to this stream.
  Stream<void> get onPlayerCompletion => _completionController.stream;

  /// Stream of player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  Stream<String> get onPlayerError =>
      _errorController.stream; //! TODO handle error stream

  /// Stream of current playing index.
  ///
  /// Events are sent when current index of a player is being changed.
  Stream<int> get onCurrentAudioIndexChanged =>
      _currentPlayingIndexController.stream;

  PlayerState _audioPlayerState;

  PlayerState get state => _audioPlayerState;

  //code for ios

  final StreamController<AudioPlayerState> _iPlayerStateController =
      new StreamController.broadcast();

  final StreamController<Duration> _iPositionController =
      new StreamController.broadcast();


  AudioPlayerState _istate = AudioPlayerState.STOPPED;
  Duration _iduration = const Duration();

  /// Initializes AudioPlayer
  ///
  AudioPlayer() {
    if(Platform.isAndroid) {
      print('Android device code initialization');
      _playerState = PlayerState.RELEASED;
  //    _playerId = _uuid.v4();
      players['123456'] = this;
      _channel.setMethodCallHandler(platformCallHandler);
    } else if(Platform.isIOS) {
      print('ios device code initialization');
      _channel.setMethodCallHandler(_audioPlayerStateChange);
    }
  }

  //ios 


  /// Stream for subscribing to player state change events.
  Stream<AudioPlayerState> get oniPlayerStateChanged => _iPlayerStateController.stream;

  /// Reports what the player is currently doing.
  AudioPlayerState get iState => _istate;

  /// Reports the duration of the current media being played. It might return
  /// 0 if we have not determined the length of the media yet. It is best to
  /// call this from a state listener when the state has become
  /// [AudioPlayerState.PLAYING].
  Duration get duration => _iduration;

  /// Stream for subscribing to audio position change events. Roughly fires
  /// every 200 milliseconds. Will continously update the position of the
  /// playback if the status is [AudioPlayerState.PLAYING].
  Stream<Duration> get oniAudioPositionChanged => _iPositionController.stream;



  /// Play a given url. -> ios device
  Future<void> iPlay(String url, {bool isLocal: false}) async {
      return await _channel.invokeMethod('play', {'url': url, 'isLocal': isLocal});
  }

  /// Plays an audio. android device
  ///
  /// If [PlayerMode] is set to [PlayerMode.FOREGROUND], then you also need to pass:
  /// [audioNotification] for providing the foreground notification.
  Future<Result> play(
      String url, {
        bool repeatMode = false,
        bool respectAudioFocus = false,
        Duration position = const Duration(milliseconds: 0),
        PlayerMode playerMode = PlayerMode.BACKGROUND,
//        AudioNotification audioNotification,
      }) async {
    playerMode ??= PlayerMode.BACKGROUND;
    repeatMode ??= false;
    respectAudioFocus ??= false;
    position ??= Duration(milliseconds: 0);

    bool isBackground = true;
    String smallIconFileName;
    String title;
    String subTitle;
    String largeIconUrl;
    bool isLocal = false;
    int notificationActionMode;
    int notificationActionCallbackMode = 0;
    if (playerMode == PlayerMode.FOREGROUND) {
//      smallIconFileName = audioNotification.smallIconFileName;
//      title = audioNotification.title;
//      subTitle = audioNotification.subTitle;
//      largeIconUrl = audioNotification.largeIconUrl;
//      isLocal = audioNotification.isLocal;
//
//      notificationActionMode =
//      NotificationActionModeMap[audioNotification.notificationMode];
//      notificationActionCallbackMode = NotificationActionCallbackModeMap[
//      audioNotification.notificationActionCallbackMode];

      isBackground = false;
    }

    return ResultMap[await _invokeMethod('play', {
      'url': url,
      'repeatMode': repeatMode,
      'isBackground': isBackground,
      'respectAudioFocus': respectAudioFocus,
      'position': position.inMilliseconds,
      // audio notification object
      'smallIconFileName': smallIconFileName,
      'title': title,
      'subTitle': subTitle,
      'largeIconUrl': largeIconUrl,
      'isLocal': isLocal,
      'notificationActionMode': notificationActionMode,
      'notificationActionCallbackMode': notificationActionCallbackMode,
    })];
  }


  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  Future<Result> pause() async {
    return ResultMap[await _invokeMethod('pause')];
  }

  /// Plays the next song.
  ///
  /// If playing only single audio it will restart the current.
  Future<Result> next() async {
    return ResultMap[await _invokeMethod('next')];
  }

  /// Plays the previous song.
  ///
  /// If playing only single audio it will restart the current.
  Future<Result> previous() async {
    return ResultMap[await _invokeMethod('previous')];
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  Future<Result> stop() async {
    return ResultMap[await _invokeMethod('stop')];
  }

  /// Resumes the audio that has been paused.
  Future<Result> resume() async {
    return ResultMap[await _invokeMethod('resume')];
  }

  /// Releases the resources associated with this audio player.
  ///
  Future<Result> release() async {
    return ResultMap[await _invokeMethod('release')];
  }

   // ios /// Seek to a specific position in the audio stream.
  Future<void> seek(double seconds) async => await _channel.invokeMethod('seek', seconds);


  /// Moves the cursor to the desired position.
  Future<Result> seekPosition(Duration position) async {
    return ResultMap[await _invokeMethod(
        'seekPosition', {'position': position.inMilliseconds})];
  }

  /// Switches to the desired index in playlist.
  Future<Result> seekIndex(int index) async {
    return ResultMap[await _invokeMethod('seekIndex', {'index': index})];
  }

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  Future<Result> setVolume(double volume) async {
    return ResultMap[await _invokeMethod('setVolume', {'volume': volume})];
  }

  /// Get audio duration after setting url.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  Future<Duration> getDuration() async {
    int milliseconds = await _invokeMethod('getDuration');
    return Duration(milliseconds: milliseconds);
  }

  /// Gets audio current playing position
  ///
  /// the position starts from 0.
  Future<int> getCurrentPosition() async {
    return await _invokeMethod('getCurrentPosition');
  }

  /// Gets current playing audio index
  Future<int> getCurrentPlayingAudioIndex() async {
    return await _invokeMethod('getCurrentPlayingAudioIndex');
  }

  // Sets the repeat mode.
  Future<Result> setRepeatMode(bool repeatMode) async {
    return ResultMap[
    await _invokeMethod('setRepeatMode', {'repeatMode': repeatMode})];
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  Future<int> _invokeMethod(
      String method, [
        Map<String, dynamic> arguments,
      ]) async {

    if(Platform.isIOS) {
      return await _channel.invokeMethod(method);
    } else {
    arguments ??= const {};

    final Map<String, dynamic> withPlayerId = Map.of(arguments)
      ..['playerId'] = playerId;

    return _channel
        .invokeMethod(method, withPlayerId)
        .then((result) => (result as int));
    }
  }


  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final playerId = callArgs['playerId'] as String;
    final AudioPlayer player = players[playerId];
    final value = callArgs['value'];

    switch (call.method) {
      case 'audio.onDurationChanged':
        Duration newDuration = Duration(milliseconds: value);
        player._durationController.add(newDuration);
        break;
      case 'audio.onCurrentPositionChanged':
        Duration newDuration = Duration(milliseconds: value);
        player._positionController.add(newDuration);
        break;
      case 'audio.onStateChanged':
        player._playerState = PlayerStateMap[value];
        player._playerStateController.add(player._playerState);
        break;
      case 'audio.onCurrentPlayingAudioIndexChange':
        player._currentPlayingIndexController.add(value);
        print("track changed to: $value");
        break;
//      case 'audio.onAudioSessionIdChange':
//        player._audioSessionIdController.add(value);
//        break;
//      case 'audio.onNotificationActionCallback':
//        player._notificationActionController
//            .add(NotificationActionNameMap[value]);
//        break;
      case 'audio.onError':
        player._playerState = PlayerState.STOPPED; //! TODO maybe released?
        player._errorController.add(value);
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }


  static void _log(String param) {
    if (logEnabled) {
      print(param);
    }
  }

  Future<void> dispose() async {
    List<Future> futures = [];
    await _invokeMethod('dispose');
    if (!_playerStateController.isClosed) {
      futures.add(_playerStateController.close());
    }
    if (!_positionController.isClosed) {
      futures.add(_positionController.close());
    }
    if (!_durationController.isClosed) {
      futures.add(_durationController.close());
    }
    if (!_completionController.isClosed) {
      futures.add(_completionController.close());
    }
    if (!_errorController.isClosed) {
      futures.add(_errorController.close());
    }
    if (!_currentPlayingIndexController.isClosed) {
      futures.add(_currentPlayingIndexController.close());
    }
//    if (!_audioSessionIdController.isClosed) {
//      futures.add(_audioSessionIdController.close());
//    }
//    if (!_notificationActionController.isClosed) {
//      futures.add(_notificationActionController.close());
//    }
    await Future.wait(futures);
  }

  Future<void> _audioPlayerStateChange(MethodCall call) async {
    switch (call.method) {
      case "audio.onCurrentPosition":
        assert(_istate == AudioPlayerState.PLAYING);
        _positionController.add(new Duration(milliseconds: call.arguments));
        break;
      case "audio.onStart":
        _istate = AudioPlayerState.PLAYING;
        _iPlayerStateController.add(AudioPlayerState.PLAYING);
        _iduration = new Duration(milliseconds: call.arguments);
        break;
      case "audio.onPause":
        _istate = AudioPlayerState.PAUSED;
        _iPlayerStateController.add(AudioPlayerState.PAUSED);
        break;
      case "audio.onStop":
        _istate = AudioPlayerState.STOPPED;
        _iPlayerStateController.add(AudioPlayerState.STOPPED);
        break;
      case "audio.onComplete":
        _istate = AudioPlayerState.COMPLETED;
        _iPlayerStateController.add(AudioPlayerState.COMPLETED);
        break;
      case "audio.onError":
        // If there's an error, we assume the player has stopped.
        _istate = AudioPlayerState.STOPPED;
        _iPlayerStateController.addError(call.arguments);
        // TODO: Handle error arguments here. It is not useful to pass this
        // to the client since each platform creates different error string
        // formats so we can't expect client to parse these.
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }



}
