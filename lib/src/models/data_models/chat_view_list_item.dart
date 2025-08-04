import '../../values/enumeration.dart';
import '../../values/typedefs.dart';
import '../omit.dart';
import 'chat_settings.dart';
import 'chat_user.dart';
import 'message.dart';

/// Model class representing a user or group in the chat list.
class ChatViewListItem {
  /// Creates a user or group object for the chat list.
  const ChatViewListItem({
    required this.id,
    required this.name,
    this.chatRoomType = ChatRoomType.oneToOne,
    this.typingUsers = const <ChatUser>{},
    this.userActiveStatus = UserActiveStatus.offline,
    this.settings = const ChatSettings(),
    this.lastMessage,
    this.imageUrl,
    this.unreadCount,
  });

  /// Unique identifier for the user or group.
  final String id;

  /// Provides name of the user or group.
  final String name;

  /// Provides last message in chat list.
  final Message? lastMessage;

  /// Provides image URL for user or group profile in chat list.
  final String? imageUrl;

  /// Provides unread message count for user or group in chat list.
  final int? unreadCount;

  /// Type of chat: user or group.
  ///
  /// Defaults to [ChatRoomType.oneToOne].
  final ChatRoomType chatRoomType;

  /// User's active status in the chat list.
  ///
  /// Defaults to [UserActiveStatus.offline].
  final UserActiveStatus userActiveStatus;

  /// Set of users currently typing in the chat.
  final Set<ChatUser> typingUsers;

  /// Settings for the chat list view.
  final ChatSettings settings;

  ChatViewListItem copyWith({
    Defaulted<String> id = const Omit(),
    Defaulted<String> name = const Omit(),
    Defaulted<ChatRoomType> chatRoomType = const Omit(),
    Defaulted<Set<ChatUser>> typingUsers = const Omit(),
    Defaulted<UserActiveStatus> userActiveStatus = const Omit(),
    Defaulted<ChatSettings> settings = const Omit(),
    Defaulted<Message>? lastMessage = const Omit(),
    Defaulted<String>? imageUrl = const Omit(),
    Defaulted<int>? unreadCount = const Omit(),
  }) {
    return ChatViewListItem(
      id: id is Omit ? this.id : id as String,
      name: name is Omit ? this.name : name as String,
      chatRoomType: chatRoomType is Omit
          ? this.chatRoomType
          : chatRoomType as ChatRoomType,
      typingUsers:
          typingUsers is Omit ? this.typingUsers : typingUsers as Set<ChatUser>,
      userActiveStatus: userActiveStatus is Omit
          ? this.userActiveStatus
          : userActiveStatus as UserActiveStatus,
      settings: settings is Omit ? this.settings : settings as ChatSettings,
      lastMessage:
          lastMessage is Omit ? this.lastMessage : lastMessage as Message?,
      imageUrl: imageUrl is Omit ? this.imageUrl : imageUrl as String?,
      unreadCount: unreadCount is Omit ? this.unreadCount : unreadCount as int?,
    );
  }
}
