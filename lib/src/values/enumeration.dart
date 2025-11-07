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

import '../extensions/extensions.dart';
import '../models/data_models/chat_list_item.dart';

/// {@template chatview_utils.enumeration.MessageType}
/// Defines the various message types in ChatView.
/// - [image]: An image message.
/// - [text]: A text message.
/// - [voice]: A voice message (Android & iOS only).
/// - [custom]: A custom message type.
/// {@endtemplate}
enum MessageType {
  image,
  text,

  /// Only supported on android and ios
  voice,
  custom;

  bool get isImage => this == image;

  bool get isText => this == text;

  bool get isVoice => this == voice;

  bool get isCustom => this == custom;

  static MessageType? tryParse(String? value) {
    final type = value?.trim().toLowerCase();
    if (type?.isEmpty ?? true) return null;
    if (type == image.name.toLowerCase()) {
      return image;
    } else if (type == text.name.toLowerCase()) {
      return text;
    } else if (type == voice.name.toLowerCase()) {
      return voice;
    } else if (type == custom.name.toLowerCase()) {
      return custom;
    }
    return null;
  }
}

/// {@template chatview_utils.enumeration.TypeWriterStatus}
/// Indicates whether the user is currently typing or has finished typing.
/// - [typing]: User is still typing.
/// - [typed]: User has completed typing.
/// {@endtemplate}
enum TypeWriterStatus {
  typing,
  typed;

  bool get isTyping => this == typing;

  bool get isTyped => this == typed;
}

/// {@template chatview_utils.enumeration.MessageStatus}
/// Represents the current state of a message from sending to delivery.
/// - [read]: Opened by the recipient.
/// - [delivered]: Successfully delivered.
/// - [undelivered]: Failed to deliver.
/// - [pending]: Message is being sent.
/// {@endtemplate}
enum MessageStatus {
  read,
  delivered,
  undelivered,
  pending;

  bool get isRead => this == read;

  bool get isDelivered => this == delivered;

  bool get isUndelivered => this == undelivered;

  bool get isPending => this == pending;

  static MessageStatus? tryParse(String? value) {
    final status = value?.trim().toLowerCase();
    if (status?.isEmpty ?? true) return null;
    if (status == read.name.toLowerCase()) {
      return read;
    } else if (status == delivered.name.toLowerCase()) {
      return delivered;
    } else if (status == undelivered.name.toLowerCase()) {
      return undelivered;
    } else if (status == pending.name.toLowerCase()) {
      return pending;
    }
    return null;
  }
}

/// {@template chatview_utils.enumeration.ImageType}
/// Defines the different types of image sources.
/// - [asset]: Image from local assets.
/// - [network]: Image from a network URL.
/// - [base64]: Image encoded in base64 format.
/// {@endtemplate}
enum ImageType {
  asset,
  network,
  base64;

  bool get isNetwork => this == network;

  bool get isAsset => this == asset;

  bool get isBase64 => this == base64;

  static ImageType? tryParse(String? value) {
    final type = value?.trim().toLowerCase();
    if (type?.isEmpty ?? true) return null;
    if (type == asset.name.toLowerCase()) {
      return asset;
    } else if (type == network.name.toLowerCase()) {
      return network;
    } else if (type == base64.name.toLowerCase()) {
      return base64;
    }
    return null;
  }
}

/// {@template chatview_utils.enumeration.ChatViewState}
/// Represents the different states of the chat view.
/// - [hasMessages]: Chat has messages to display.
/// - [noData]: No messages available.
/// - [loading]: Messages are being loaded.
/// - [error]: An error occurred while loading messages.
/// {@endtemplate}
enum ChatViewState {
  hasMessages,
  noData,
  loading,
  error;

  bool get isHasMessages => this == hasMessages;

  bool get isNoData => this == noData;

  bool get isLoading => this == loading;

  bool get isError => this == error;
}

/// {@template chatview_utils.enumeration.ChatPaginationDirection}
/// Defines the direction for pagination in the chat view.
/// - [previous]: Load previous messages when reached to the top of the chat
/// list.
/// - [next]: Load next messages when reached to the bottom of the chat list.
/// {@endtemplate}
enum ChatPaginationDirection {
  /// Load previous messages when reached to the top of the chat list.
  previous,

  /// Load next messages when reached to the bottom of the chat list.
  next;

  bool get isPrevious => this == previous;

  bool get isNext => this == next;
}

/// An enumeration of user status.
enum UserActiveStatus {
  /// user is active
  online,

  /// user is inactive
  offline;

  /// is user inactive
  bool get isOnline => this == online;

  /// is user active
  bool get isOffline => this == offline;
}

/// Extension methods for [UserActiveStatus], providing utilities
/// for parsing and handling user status values.
extension UserActiveStatusExtension on UserActiveStatus {
  /// Parses a string value and returns the corresponding [UserActiveStatus].
  ///
  /// - If the [value] is `null` or empty,
  /// it defaults to [UserActiveStatus.offline].
  /// - If the [value] matches `online`
  /// (case-insensitive), it returns [UserActiveStatus.online].
  /// - For all other cases, it defaults to [UserActiveStatus.offline].
  ///
  /// Example:
  /// ```dart
  /// final status = UserStatus.parse('online');
  /// print(status); // Output: UserStatus.online
  /// ```
  ///
  /// [value]: The input string to parse.
  /// Returns the corresponding [UserActiveStatus].
  static UserActiveStatus parse(String? value) {
    final safeValue = value?.trim().toLowerCase() ?? '';
    if (safeValue.isEmpty) return UserActiveStatus.offline;
    if (safeValue == UserActiveStatus.online.name) {
      return UserActiveStatus.online;
    } else {
      return UserActiveStatus.offline;
    }
  }
}

/// An enumeration representing the pin status of a chat.
enum PinStatus {
  /// Indicates that the chat is pinned.
  pinned,

  /// Indicates that the chat is not pinned.
  unpinned;

  /// Returns `true` if the chat is pinned.
  bool get isPinned => this == pinned;

  /// Returns `true` if the chat is not pinned.
  bool get isUnpinned => this == unpinned;
}

/// Provides utility methods for [PinStatusExtension].
extension PinStatusExtension on PinStatus {
  /// Parses a string value and returns the corresponding [PinStatus].
  ///
  /// **Parameters:**
  /// - (required): [value] The input string to parse.
  ///
  /// Returns the corresponding [PinStatus] if the value matches.
  /// Defaults to [PinStatus.unpinned] if the input is empty or doesn't match
  /// any status.
  static PinStatus parse(String? value) {
    final type = value?.trim().toLowerCase() ?? '';
    if (type.isEmpty) return PinStatus.unpinned;
    if (type == PinStatus.pinned.name.toLowerCase()) {
      return PinStatus.pinned;
    } else {
      return PinStatus.unpinned;
    }
  }
}

/// An enumeration representing the mute status of a chat.
enum MuteStatus {
  /// Indicates that the chat is muted.
  muted,

  /// Indicates that the chat is not muted.
  unmuted;

  /// Returns `true` if the chat is muted.
  bool get isMuted => this == muted;

  /// Returns `true` if the chat is not muted.
  bool get isUnmuted => this == unmuted;
}

/// Provides utility methods for [MuteStatusExtension].
extension MuteStatusExtension on MuteStatus {
  /// Parses a string value and returns the corresponding [MuteStatus].
  ///
  /// **Parameters:**
  /// - (required): [value] The input string to parse.
  ///
  /// Returns the corresponding [MuteStatus] if the value matches.
  /// Defaults to [MuteStatus.unmuted] if the input is empty or doesn't match
  /// any status.
  static MuteStatus parse(String? value) {
    final type = value?.trim().toLowerCase() ?? '';
    if (type.isEmpty) return MuteStatus.unmuted;
    if (type == MuteStatus.muted.name.toLowerCase()) {
      return MuteStatus.muted;
    } else {
      return MuteStatus.unmuted;
    }
  }
}

/// An enumeration representing different types of chat rooms.
enum ChatRoomType {
  /// A one-on-one private chat between two users.
  oneToOne,

  /// A group chat involving multiple users.
  group;

  /// Returns `true` if the chat room type is [oneToOne].
  bool get isOneToOne => this == oneToOne;

  /// Returns `true` if the chat room type is [group].
  bool get isGroup => this == group;
}

/// Provides utility methods for [ChatRoomTypeExtension].
extension ChatRoomTypeExtension on ChatRoomType {
  /// Parses a string value and returns the corresponding [ChatRoomType].
  ///
  /// Returns the corresponding [ChatRoomType] if the value matches,
  /// or `null` if it doesn't.
  static ChatRoomType? tryParse(String? value) {
    final safeValue = value?.trim().toLowerCase() ?? '';
    if (safeValue == ChatRoomType.oneToOne.name.toLowerCase()) {
      return ChatRoomType.oneToOne;
    } else if (safeValue == ChatRoomType.group.name.toLowerCase()) {
      return ChatRoomType.group;
    } else {
      return null;
    }
  }
}

/// Enum for different chat list sorting options (for internal use only)
enum ChatListSortBy {
  /// No sorting applied.
  none,

  /// Pin chats first (sorted by pin time), then unpinned by message date/time
  pinFirstByPinTime;

  int sort(ChatListItem chat1, ChatListItem chat2) {
    switch (this) {
      case none:
        return 0;
      case pinFirstByPinTime:
        final isChatAPinned = chat1.settings.pinStatus.isPinned;
        final isChatBPinned = chat2.settings.pinStatus.isPinned;

        // 1. Pinned chats first
        if (isChatAPinned && !isChatBPinned) return -1;
        if (!isChatAPinned && isChatBPinned) return 1;

        // 2. Sort pinned chats by pinTime descending (latest first)
        if (isChatAPinned && isChatBPinned) {
          final pinTimeA = chat1.settings.pinTime;
          final pinTimeB = chat2.settings.pinTime;
          if (pinTimeA != null && pinTimeB != null) {
            return pinTimeB.compareTo(pinTimeA);
          }
          // If one has null pinTime, treat it as older
          if (pinTimeA == null && pinTimeB != null) return 1;
          if (pinTimeA != null && pinTimeB == null) return -1;
        }

        // 3. Sort unpinned chats by message date/time (newest first)
        if (!isChatAPinned && !isChatBPinned) {
          final chatBCreateAt = chat2.lastMessage?.createdAt;
          return chatBCreateAt.compareWith(chat1.lastMessage?.createdAt);
        }

        return 0;
    }
  }
}
