import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/services/chat_draft_service.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/initiator.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/recipient.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/chat_input_field.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/chat_message_bubble.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_form_bottom_sheet.dart';

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

  /// Draft text loaded from `ChatDraftService` on init; passed as
  /// `initialText` to `ChatInputField` so the input is pre-populated.
  String? _initialDraft;

  /// Debounces draft writes to `SharedPreferences` on every keystroke.
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _currentUserId = widget.currentUserId;
    _initialDraft = ChatDraftService.instance.get(
      userId: widget.currentUserId,
      conversationId: widget.conversationId,
    );
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Debounced draft persistence — fires on every keystroke inside
  /// `ChatInputField`. Saves at most once per 500 ms; whitespace-only text
  /// clears the draft via the service's own trim logic.
  void _handleDraftChanged(String text) {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      ChatDraftService.instance.save(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        text: text,
      );
    });
  }

  Future<void> _loadMessages() async {
    final conversationsCubit = context.read<ConversationsCubit>();
    await conversationsCubit.fetchChatMessages(widget.conversationId);

    // Opening the thread is what clears its unread state — one pass over the
    // inbound backlog rather than a request per message per build frame.
    unawaited(
      conversationsCubit.markConversationAsRead(
        widget.conversationId,
        currentUserId: widget.currentUserId,
      ),
    );

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Send acquired — clear any saved draft immediately so it doesn't
    // resurrect on a subsequent chat open. Also cancel a pending debounce
    // in case the user hit send within 500 ms of typing.
    _draftDebounce?.cancel();
    ChatDraftService.instance.clear(
      userId: widget.currentUserId,
      conversationId: widget.conversationId,
    );

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
    final appState = context.read<AppCubit>().state;
    final isStylist = appState.isStylist;

    // Determine the other person's ID regardless of which params were passed.
    // Pick whichever of recipient/initiator doesn't belong to the current user.
    final otherUserId = () {
      final recipientId = widget.recipient?.id;
      final initiatorId = widget.initiator?.id;
      if (recipientId != null && recipientId.toString() != _currentUserId) {
        return recipientId;
      }
      if (initiatorId != null && initiatorId.toString() != _currentUserId) {
        return initiatorId;
      }
      return null;
    }();

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
          actions: isStylist && otherUserId != null
              ? [
                  IconButton(
                    tooltip: 'Request Payment',
                    icon: const Icon(Icons.attach_money),
                    onPressed: () => showPaymentRequestForm(
                      context,
                      recipientId: otherUserId,
                      conversationId: widget.conversationId,
                    ),
                  ),
                ]
              : null,
        ),
        body: BlocConsumer<ConversationsCubit, ConversationsState>(
          listenWhen: (prev, curr) =>
              prev.chatMessagesState.data != curr.chatMessagesState.data,
          listener: (context, state) {
            // Messages that arrive from the polling loop while the thread is
            // open should not resurrect the unread badge.
            unawaited(
              context.read<ConversationsCubit>().markConversationAsRead(
                    widget.conversationId,
                    currentUserId: widget.currentUserId,
                  ),
            );
          },
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

                            return ChatMessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        ),
                ),
                ChatInputField(
                  onSend: _handleSendMessage,
                  onChanged: _handleDraftChanged,
                  initialText: _initialDraft,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
