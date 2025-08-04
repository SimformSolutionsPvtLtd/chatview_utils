/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/foundation.dart';

import '../../extensions/extensions.dart';
import '../../values/enumeration.dart';
import 'reaction.dart';
import 'reply_message.dart';

class Message {
  Message({
    required this.message,
    required this.createdAt,
    required this.sentBy,
    this.id = '',
    this.replyMessage = const ReplyMessage(),
    this.messageType = MessageType.text,
    this.voiceMessageDuration,
    this.updateAt,
    this.update,
    MessageStatus status = MessageStatus.pending,
    Reaction? reaction,
  })  : reaction = reaction ?? Reaction(reactions: [], reactedUserIds: []),
        _status = ValueNotifier(status),
        assert(
          defaultTargetPlatform.isAudioWaveformsSupported ||
              !messageType.isVoice,
          'Voice messages are only supported with android and ios platform',
        );

  factory Message.fromJson(Map<String, dynamic> json) {
    final replyMessageData = json[_replyMessage];
    final updateData = json[_update];
    final reactionData = json[_reaction];
    return Message(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
      sentBy: json['sentBy']?.toString() ?? '',
      replyMessage: replyMessageData is Map<String, dynamic>
          ? ReplyMessage.fromJson(replyMessageData)
          : const ReplyMessage(),
      reaction: reactionData is Map<String, dynamic>
          ? Reaction.fromJson(reactionData)
          : Reaction(reactions: [], reactedUserIds: []),
      messageType: MessageType.tryParse(json['message_type']?.toString()) ??
          MessageType.text,
      voiceMessageDuration: Duration(
        microseconds: int.tryParse(json[_voiceMessageDuration].toString()) ?? 0,
      ),
      status: MessageStatus.tryParse(json['status']?.toString()) ??
          MessageStatus.pending,
      update: updateData is Map<String, dynamic> ? updateData : null,
      updateAt: DateTime.tryParse(json[_updateAt].toString()),
    );
  }

  static const String _replyMessage = 'reply_message';
  static const String _reaction = 'reaction';
  static const String _voiceMessageDuration = 'voice_message_duration';
  static const String _updateAt = 'update_at';
  static const String _update = 'update';

  /// Unique identifier for the message.
  final String id;

  /// The message content, which can be text, an image path,
  /// or an audio file path.
  final String message;

  /// The date and time when the message was created.
  final DateTime createdAt;

  /// The sender's unique identifier (ID).
  final String sentBy;

  /// The replied message, if the user has replied to any message.
  final ReplyMessage replyMessage;

  /// Represents reaction on message.
  final Reaction reaction;

  /// Represents the type of message.
  ///
  /// {@macro chatview_utils.enumeration.MessageType}
  final MessageType messageType;

  final DateTime? updateAt;

  final Map<String, dynamic>? update;

  /// Status of the message.
  final ValueNotifier<MessageStatus> _status;

  /// Provides max duration for recorded voice message.
  Duration? voiceMessageDuration;

  /// Provides message's current status.
  ///
  /// {@macro chatview_utils.enumeration.MessageStatus}
  MessageStatus get status => _status.value;

  /// A [ValueListenable] for [MessageStatus] that notifies listeners
  /// when the message state changes.
  ///
  /// Helps avoid `setState((){})`, ensuring efficient UI updates
  /// when message receipts change.
  ValueListenable<MessageStatus> get statusNotifier => _status;

  /// Updates the message status and triggers UI rebuilds
  /// for configured listeners.
  set setStatus(MessageStatus messageStatus) => _status.value = messageStatus;

  Map<String, dynamic> toJson({bool includeNullValues = true}) {
    final data = <String, dynamic>{
      'id': id,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'sentBy': sentBy,
      'status': _status.value.name,
      'message_type': messageType.name,
    };

    if (includeNullValues) {
      data[_replyMessage] = replyMessage.toJson();
      data[_reaction] = reaction.toJson();
      data[_voiceMessageDuration] = voiceMessageDuration?.inMicroseconds;
      data[_updateAt] = updateAt?.toIso8601String();
      data[_update] = update;
    } else {
      if (!replyMessage.isEmpty) data[_replyMessage] = replyMessage.toJson();
      if (!reaction.isEmpty) data[_reaction] = reaction.toJson();
      if (voiceMessageDuration case final duration?) {
        data[_voiceMessageDuration] = duration.inMicroseconds;
      }
      if (updateAt case final updateAt?) {
        data[_updateAt] = updateAt.toIso8601String();
      }
      if (update?.isNotEmpty ?? false) data[_update] = update;
    }

    return data;
  }

  Message copyWith({
    String? id,
    String? message,
    DateTime? createdAt,
    String? sentBy,
    ReplyMessage? replyMessage,
    Reaction? reaction,
    MessageType? messageType,
    Duration? voiceMessageDuration,
    MessageStatus? status,
    DateTime? updateAt,
    Map<String, String>? update,
    bool forceNullValue = false,
  }) {
    return Message(
      id: id ?? this.id,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      sentBy: sentBy ?? this.sentBy,
      messageType: messageType ?? this.messageType,
      voiceMessageDuration: forceNullValue
          ? voiceMessageDuration
          : voiceMessageDuration ?? this.voiceMessageDuration,
      reaction: reaction ?? this.reaction,
      replyMessage: replyMessage ?? this.replyMessage,
      updateAt: forceNullValue ? updateAt : updateAt ?? this.updateAt,
      update: forceNullValue ? update : update ?? this.update,
      status: status ?? this.status,
    );
  }

  @override
  String toString() => '''Message(${toJson()})''';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.sentBy == sentBy &&
        other.replyMessage == replyMessage &&
        other.reaction == reaction &&
        other.messageType == messageType &&
        other.voiceMessageDuration == voiceMessageDuration &&
        other.status == status &&
        mapEquals(other.update, update) &&
        other.updateAt == updateAt;
  }

  @override
  int get hashCode => Object.hashAllUnordered([
        id,
        message,
        createdAt,
        sentBy,
        replyMessage,
        reaction,
        messageType,
        voiceMessageDuration,
        status,
        update,
        updateAt,
      ]);
}
