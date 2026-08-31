import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/services/chat_draft_service.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/conversations/conversations_list/widgets/unread_count_badge.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';

@RoutePage()
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key, this.chatConversation});

  final ChatConversation? chatConversation;

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    // Always re-pull on open. The 4s badge poll only refreshes the scalar
    // count, so without this the rows themselves (and their per-conversation
    // unread counts) could be whatever was cached at last visit — the
    // "have to restart the app to see new messages" symptom.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConversationsCubit>().fetchConversations(true);
    });
  }

  @override
  void didChangeDependencies() {
    if (widget.chatConversation != null) {
      final currentUserId = context.read<AppCubit>().state.user.id!;
      context
          .read<ConversationsCubit>()
          .fetchChatMessages(widget.chatConversation!.id!.toString());
      context.router.push(
        ConvesationChatRoute(
          recipient: widget.chatConversation!.recipient,
          initiator: widget.chatConversation!.initiator,
          conversationId: widget.chatConversation!.id!.toString(),
          currentUserId: currentUserId.toString(),
        ),
      );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Conversations',
      ),
      body: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.conversationsState.isLoading)
                const LinearProgressIndicator()
              else
                const SizedBox.shrink(),
              5.verticalSpace,
              Expanded(
                child: Builder(
                  builder: (context) {
                    final conversations = state.conversationsState.data ?? [];
                    if (conversations.isEmpty) {
                      return const Center(
                        child: AppText(
                          text: 'No conversations found.',
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: conversations.length,
                      separatorBuilder: (context, index) => 5.verticalSpace,
                      itemBuilder: (context, index) {
                        final conversation =
                            state.conversationsState.data![index];

                        final currentUserId =
                            context.read<AppCubit>().state.user.id?.toString();
                        final isInitiator =
                            currentUserId == conversation.initiatorId;
                        final isRecipient =
                            currentUserId == conversation.recipientId;
                        final unreadCount =
                            unreadCountFor(conversation, currentUserId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: isInitiator &&
                                    conversation.recipient?.avatar != null
                                ? CachedNetworkImageProvider(
                                    conversation.recipient!.avatar!
                                        .completeImagePath(),
                                  )
                                : isRecipient &&
                                        conversation.initiator?.avatar != null
                                    ? CachedNetworkImageProvider(
                                        conversation.initiator!.avatar!
                                            .toString()
                                            .completeImagePath(),
                                      )
                                    : null,
                            child: isInitiator &&
                                    conversation.recipient?.avatar == null
                                ? const Icon(Icons.person)
                                : isRecipient &&
                                        conversation.initiator?.avatar == null
                                    ? const Icon(Icons.person)
                                    : null,
                          ),
                          tileColor: Colors.white,
                          title: AppText(
                            text: isInitiator
                                ? conversation.recipient?.name ?? 'Unknown'
                                : conversation.initiator?.name ?? 'Unknown',
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          subtitle: _buildSubtitle(context, conversation),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                text: conversation.updatedAt != null
                                    ? (conversation.updatedAt!).toTimeAgo()
                                    : '',
                                fontSize: 10,
                              ),
                              if (unreadCount > 0)
                                UnreadCountBadge(
                                  key: const Key(
                                    'conversation_unread_badge',
                                  ),
                                  count: unreadCount,
                                )
                              else if (conversation.messages != null &&
                                  conversation.messages!.isNotEmpty &&
                                  conversation.messages!.first.senderId ==
                                      currentUserId &&
                                  (conversation.messages!.first.isRead ??
                                      false)) ...[
                                5.verticalSpace,
                                const Icon(
                                  Icons.done_all,
                                  size: 14,
                                  color: Colors.green,
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            if (currentUserId == null) return;

                            context
                                .read<ConversationsCubit>()
                                .startPollingMessages(
                                  conversation.id!.toString(),
                                );
                            context.router.push(
                              ConvesationChatRoute(
                                recipient: conversation.recipient,
                                initiator: conversation.initiator,
                                conversationId: conversation.id!.toString(),
                                currentUserId: currentUserId,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Row subtitle priority (matches WhatsApp / iMessage):
  /// 1. Local draft (green) — this user was mid-composition
  /// 2. Latest message (primary color if unread from other user, grey
  ///    otherwise)
  /// 3. Placeholder — no messages yet
  Widget _buildSubtitle(BuildContext context, ChatConversation conversation) {
    final currentUserId = context.read<AppCubit>().state.user.id?.toString();
    final conversationId = conversation.id?.toString();

    if (currentUserId != null && conversationId != null) {
      final draft = ChatDraftService.instance.get(
        userId: currentUserId,
        conversationId: conversationId,
      );
      if (draft != null && draft.trim().isNotEmpty) {
        return AppText(
          text: 'Draft: $draft',
          color: Colors.green,
        );
      }
    }

    final messages = conversation.messages;
    if (messages == null || messages.isEmpty) {
      return const AppText(text: 'No messages yet', color: Colors.grey);
    }

    final last = messages.first;
    final unreadFromOther =
        last.senderId != currentUserId && last.isRead == false;
    return AppText(
      text: last.text ?? '',
      color: unreadFromOther ? AppColors.primaryColor : Colors.grey,
    );
  }
}
