import 'package:flutter/cupertino.dart';

import '../../values/enumeration.dart';
import '../../values/typedefs.dart';
import '../omit.dart';

@immutable
class ChatSettings {
  const ChatSettings({
    this.muteStatus = MuteStatus.unmuted,
    this.pinStatus = PinStatus.unpinned,
    this.pinTime,
  });

  final MuteStatus muteStatus;
  final PinStatus pinStatus;
  final DateTime? pinTime;

  ChatSettings copyWith({
    Defaulted<MuteStatus> muteStatus = const Omit(),
    Defaulted<PinStatus> pinStatus = const Omit(),
    Defaulted<DateTime>? pinTime = const Omit(),
  }) {
    return ChatSettings(
      muteStatus:
          muteStatus is Omit ? this.muteStatus : muteStatus as MuteStatus,
      pinStatus: pinStatus is Omit ? this.pinStatus : pinStatus as PinStatus,
      pinTime: pinTime is Omit ? this.pinTime : pinTime as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatSettings &&
        runtimeType == other.runtimeType &&
        other.muteStatus == muteStatus &&
        other.pinStatus == pinStatus &&
        other.pinTime == pinTime;
  }

  @override
  int get hashCode => Object.hash(muteStatus, pinStatus, pinTime);

  @override
  String toString() {
    return 'ChatSettings('
        'muteStatus: $muteStatus, '
        'pinStatus: $pinStatus, '
        'pinTime: $pinTime'
        ')';
  }
}
