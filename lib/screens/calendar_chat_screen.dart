import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../providers/chat_provider.dart';
import '../models/calendar_event.dart';
import '../models/chat_message.dart';

class CalendarChatScreen extends StatefulWidget {
  const CalendarChatScreen({super.key});

  @override
  State<CalendarChatScreen> createState() => _CalendarChatScreenState();
}

class _CalendarChatScreenState extends State<CalendarChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we should use horizontal or vertical layout
            final isWideScreen = constraints.maxWidth > 800;

            if (isWideScreen) {
              // Horizontal layout: Calendar on left, Chat on right
              return Row(
                children: [
                  Expanded(flex: 1, child: _CalendarWidget()),
                  Container(
                    width: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                  Expanded(
                    flex: 1,
                    child: _ChatWidget(
                      messageController: _messageController,
                      scrollController: _scrollController,
                      onSendMessage: _sendMessage,
                    ),
                  ),
                ],
              );
            } else {
              // Vertical layout: Calendar on top, Chat on bottom
              return Column(
                children: [
                  Expanded(flex: 3, child: _CalendarWidget()),
                  Container(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                  Expanded(
                    flex: 2,
                    child: _ChatWidget(
                      messageController: _messageController,
                      scrollController: _scrollController,
                      onSendMessage: _sendMessage,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, child) {
        return Column(
          children: [
            Container(
              child: TableCalendar<CalendarEvent>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: calendarProvider.focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(calendarProvider.selectedDay, day);
                },
                eventLoader: calendarProvider.getEventsForDay,
                calendarFormat: calendarProvider.calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                onDaySelected: (selectedDay, focusedDay) {
                  calendarProvider.setSelectedDay(selectedDay);
                  calendarProvider.setFocusedDay(focusedDay);
                },
                onFormatChanged: (format) {
                  calendarProvider.setCalendarFormat(format);
                },
                onPageChanged: (focusedDay) {
                  calendarProvider.setFocusedDay(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _EventsList(
                events:
                    calendarProvider.selectedDay != null
                        ? calendarProvider.getEventsForDay(
                          calendarProvider.selectedDay!,
                        )
                        : calendarProvider.getEventsForDay(DateTime.now()),
                selectedDate: calendarProvider.selectedDay ?? DateTime.now(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChatWidget extends StatelessWidget {
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onSendMessage;

  const _ChatWidget({
    required this.messageController,
    required this.scrollController,
    required this.onSendMessage,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.messages.isEmpty && !chatProvider.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Start a conversation!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ask me anything about your calendar\nor general questions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  return _MessageBubble(message: message);
                },
              );
            },
          ),
        ),
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (chatProvider.isLoading) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(chatProvider.loadingStatus),
                    if (chatProvider.currentFunction != null) ...[
                      SizedBox(width: 8),
                      Icon(
                        chatProvider.currentFunction == 'add_schedule'
                            ? Icons.event
                            : chatProvider.currentFunction == 'get_current_time'
                            ? Icons.access_time
                            : Icons.build,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              );
            }
            if (chatProvider.error != null) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProvider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => chatProvider.clearError(),
                      child: Text('Dismiss'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return IconButton(
                      onPressed: chatProvider.isLoading ? null : onSendMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? null : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : null,
                ),
              ),
              child:
                  isUser
                      ? Text(
                        message.content,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                      : MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<CalendarEvent> events;
  final DateTime selectedDate;

  const _EventsList({required this.events, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No events for ${DateFormat('MMM dd').format(selectedDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add an event',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            leading: Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 24),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                context.read<CalendarProvider>().removeEvent(
                  selectedDate,
                  event,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
