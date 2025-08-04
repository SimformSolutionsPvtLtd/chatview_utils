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
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../extensions/extensions.dart';
import '../models/data_models/chat_user.dart';
import '../models/data_models/message.dart';
import '../models/data_models/suggestion_item_data.dart';
import '../values/constants.dart';
import '../values/enumeration.dart';

base class ChatController {
  ChatController({
    required this.initialMessageList,
    required this.scrollController,
    required List<ChatUser> otherUsers,
    required this.currentUser,
  }) : _otherUsers = otherUsers.toMap<String, ChatUser>(
          getKey: (user) => user.id,
        );

  /// Caches old message list before replacing it with a temporary new one.
  final Set<Message> _oldMessageList = {};

  /// Represents initial message list in chat which can be add by user.
  List<Message> initialMessageList;

  ScrollController scrollController;

  final Map<String, ChatUser> _otherUsers;

  /// Represents list of chat users
  List<ChatUser> get otherUsers => _otherUsers.values.toList();

  Map<String, ChatUser> get otherUsersMap => Map.of(_otherUsers);

  /// Signifies whether there's an initial message list cached when it was
  /// replaced with a temporary one (like for showing really old reply
  /// message or searched message).
  bool get canRevertToInitialMessageList => _oldMessageList.isNotEmpty;

  /// Provides current user which is sending messages.
  final ChatUser currentUser;

  /// Allow user to show typing indicator defaults to false.
  final ValueNotifier<bool> _showTypingIndicator = ValueNotifier(false);

  /// TypingIndicator as [ValueListenable] for `GroupedChatList` widget's
  /// typingIndicator [ValueListenableBuilder].
  ///  Use this for listening typing indicators
  ///   ```dart
  ///    chatController.typingIndicatorNotifier.addListener((){});
  ///  ```
  /// For more functionalities see [ValueListenable].
  ValueListenable<bool> get typingIndicatorNotifier => _showTypingIndicator;

  /// Indicates whether the typing indicator is displayed.
  /// Returns `true` if the typing indicator is shown, otherwise `false`
  bool get showTypingIndicator => _showTypingIndicator.value;

  /// Setter for changing values of typingIndicator
  /// ```dart
  ///  chatController.setTypingIndicator = true; // for showing indicator
  ///  chatController.setTypingIndicator = false; // for hiding indicator
  ///  ````
  set setTypingIndicator(bool value) => _showTypingIndicator.value = value;

  /// Allow user to add reply suggestions defaults to empty.
  final ValueNotifier<List<SuggestionItemData>> _replySuggestion =
      ValueNotifier([]);

  /// newSuggestions as [ValueListenable] for `SuggestionList` widget's
  /// [ValueListenableBuilder].
  ///  Use this to listen when suggestion gets added
  ///   ```dart
  ///    chatController.newSuggestions.addListener((){});
  ///  ```
  /// For more functionalities see [ValueListenable].
  ValueListenable<List<SuggestionItemData>> get newSuggestions =>
      _replySuggestion;

  /// Used to add reply suggestions.
  void addReplySuggestions(List<SuggestionItemData> suggestions) =>
      _replySuggestion.value = suggestions;

  /// Used to remove reply suggestions.
  void removeReplySuggestions() => _replySuggestion.value = [];

  /// Represents message stream of chat
  final StreamController<List<Message>> messageStreamController =
      StreamController.broadcast();

  /// Callback enabling reset of ListView when scrolling to the top is
  /// inefficient.
  late VoidCallback? _listViewResetCallback;

  /// Used to add message in message list.
  void addMessage(Message message) {
    // New message should always be added to the initial message list and not
    // to the temporary one.
    revertToInitialMessageList(shouldStream: false);
    initialMessageList.add(message);
    if (messageStreamController.isClosed) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Caches the existing message list before replacing it with a temporary new
  /// one. Useful for features like loading up really old reply message or
  /// searching for some message.
  void replaceMessageList(List<Message> messageList) {
    _oldMessageList
      ..clear()
      ..addAll(initialMessageList.toList());
    initialMessageList = messageList;
    if (messageStreamController.isClosed) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Enables reverting to the initial message list, replacing the temporary
  /// message list set using [replaceMessageList].
  void revertToInitialMessageList({bool shouldStream = true}) {
    // If _oldMessageList is empty, it means no previous state to revert to.
    if (_oldMessageList.isEmpty) return;

    initialMessageList = _oldMessageList.toList();
    if (messageStreamController.isClosed || !shouldStream) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Function for loading data while pagination.
  /// [direction] is used to determine whether to load previous or next data.
  void loadMoreData(
    List<Message> messageList, {
    ChatPaginationDirection direction = ChatPaginationDirection.previous,
  }) {
    if (direction.isPrevious) {
      // Passed 0 index as we need to add data before first data
      initialMessageList.insertAll(0, messageList);
    } else {
      initialMessageList.addAll(messageList);

      // Check if we've fetched partial (or all) messages of the old message
      // list.
      if (_oldMessageList.isNotEmpty) {
        final difference = _oldMessageList.difference(messageList.toSet());
        final differenceCount = difference.length;
        if (differenceCount != 0 && differenceCount != _oldMessageList.length) {
          initialMessageList.addAll(difference);
          _oldMessageList.clear();
        }
      }
    }

    if (messageStreamController.isClosed) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Function for update message by Digvijaysinh Chauhan
  void updateMessage({
    required String messageId,
    required Message newMessage,
  }) {
    final message = initialMessageList.firstWhereOrNull(
      (message) => message.id == messageId,
    );
    if (message == null) throw Exception('Message Not Found!');
    final indexOfMessage = initialMessageList.indexOf(message);
    initialMessageList[indexOfMessage] = newMessage;
    if (messageStreamController.isClosed) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Function for setting reaction on specific chat bubble
  void setReaction({
    required String emoji,
    required String messageId,
    required String userId,
  }) {
    final message = initialMessageList.firstWhereOrNull(
      (message) => message.id == messageId,
    );
    if (message == null) throw Exception('Message Not Found!');
    final reactedUserIds = message.reaction.reactedUserIds;
    final indexOfMessage = initialMessageList.indexOf(message);
    final userIndex = reactedUserIds.indexOf(userId);
    if (userIndex != -1) {
      if (message.reaction.reactions[userIndex] == emoji) {
        message.reaction
          ..reactions.removeAt(userIndex)
          ..reactedUserIds.removeAt(userIndex);
      } else {
        message.reaction.reactions[userIndex] = emoji;
      }
    } else {
      message.reaction
        ..reactions.add(emoji)
        ..reactedUserIds.add(userId);
    }
    initialMessageList[indexOfMessage] = Message(
      id: messageId,
      message: message.message,
      createdAt: message.createdAt,
      sentBy: message.sentBy,
      replyMessage: message.replyMessage,
      reaction: message.reaction,
      messageType: message.messageType,
      status: message.status,
    );
    if (messageStreamController.isClosed) return;
    messageStreamController.sink.add(initialMessageList);
  }

  /// Function to scroll to last messages in chat view
  void scrollToLastMessage({
    Duration waitFor = Constants.scrollToLastTimerDuration,
    Duration scrollFor = Constants.scrollToAnimateDuration,
  }) {
    Timer(
      waitFor,
      () {
        if (!scrollController.hasClients) return;
        _onScroll(duration: scrollFor);
      },
    );
  }

  /// Function for getting ChatUser object from user id
  ChatUser getUserFromId(String userId) {
    final user = userId == currentUser.id ? currentUser : _otherUsers[userId];
    if (user == null) throw Exception('User with ID $userId not found!');
    return user;
  }

  /// Function for updating the details of an existing user (other users).
  ///
  /// **Parameters:**
  /// - (required): [chatUser] The updated `ChatUser` object containing new
  /// user details.
  void updateOtherUser(ChatUser chatUser) =>
      _otherUsers[chatUser.id] = chatUser;

  /// Used to dispose ValueNotifiers and Streams.
  void dispose() {
    _showTypingIndicator.dispose();
    _replySuggestion.dispose();
    scrollController.dispose();
    messageStreamController.close();
  }

  /// Register the ListView reset callback. Internal use only.
  void registerListViewReset(VoidCallback callback) =>
      _listViewResetCallback = callback;

  /// Handles the scroll event assuming [_oldMessageList] would be the most
  /// latest messages list and keeping in mind flutter's limitation of
  /// scrolling past large amount of pixels.
  void _onScroll({required Duration duration}) {
    if (canRevertToInitialMessageList) revertToInitialMessageList();

    // Calculate smooth scroll limit based on device capabilities
    final scrollThreshold = _calculateScrollThreshold(
      animationDuration: duration,
      viewPortDimension: scrollController.position.viewportDimension,
    );

    if (scrollController.offset > scrollThreshold) {
      // Reset messages' list state to display starting position
      // directly instead of animating or jumping to the said
      // position.
      _listViewResetCallback?.call();
    } else {
      scrollController.animateTo(
        scrollController.positions.last.minScrollExtent,
        duration: duration,
        curve: Curves.easeIn,
      );
    }
  }

  /// Calculates the scroll threshold based on the animation duration and
  /// viewport dimension which can be achieved smoothly.
  double _calculateScrollThreshold({
    required Duration animationDuration,
    required double viewPortDimension,
  }) {
    // Assume 60 FPS, approximately 17ms per frame
    const msPerFrame = 17;
    final totalFrames = animationDuration.inMilliseconds / msPerFrame;

    // Conservative estimate: 60% of viewport dimension per frame
    final pixelsPerFrame = viewPortDimension * 0.6;

    return totalFrames * pixelsPerFrame;
  }
}
