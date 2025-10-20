import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/initiator.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/recipient.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/chat_input_field.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/chat_message_bubble.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

@RoutePage()
class ConvesationChatScreen extends StatefulWidget {
  const ConvesationChatScreen({
    required this.conversationId,
    required this.currentUserId,
    this.recipient,
    this.initiator,
    super.key,
  });

  final String conversationId;
  final String currentUserId;
  final Recipient? recipient;
  final Initiator? initiator;

  @override
  State<ConvesationChatScreen> createState() => _ConvesationChatScreenState();
}

class _ConvesationChatScreenState extends State<ConvesationChatScreen> {
  final _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _currentUserId = widget.currentUserId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final conversationsCubit = context.read<ConversationsCubit>();
    await conversationsCubit.fetchChatMessages(widget.conversationId);

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ConversationsCubit>().handleSendMessage(
          text: text,
          conversationId: widget.conversationId,
          currentUserId: _currentUserId,
          otherUserId:
              'other_user_id', // TODO: Replace with actual other user ID
        );

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInitiator = _currentUserId == widget.initiator?.id.toString();
    final isRecipient = _currentUserId == widget.recipient?.id.toString();
    return WillPopScope(
      onWillPop: () async {
        context.read<ConversationsCubit>().stopPollingMessages();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: isInitiator
              ? widget.recipient?.name ?? 'Chat'
              : isRecipient
                  ? widget.initiator?.name ?? 'Chat'
                  : 'Chat',
        ),
        body: BlocBuilder<ConversationsCubit, ConversationsState>(
          builder: (context, state) {
            final messages = state.chatMessagesState.data ?? [];

            return Column(
              children: [
                if (state.chatMessagesState.isLoading)
                  const LinearProgressIndicator()
                else
                  const SizedBox.shrink(),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('No messages yet'),
                        )
                      : ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUser =
                                message.senderId == _currentUserId;

                            if (!isCurrentUser && !(message.isRead ?? true)) {
                              context
                                  .read<ConversationsCubit>()
                                  .markMessagesAsRead(
                                    widget.conversationId,
                                    message.id.toString(),
                                  );
                            }

                            return ChatMessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        ),
                ),
                ChatInputField(onSend: _handleSendMessage),
              ],
            );
          },
        ),
      ),
    );
  }
}
