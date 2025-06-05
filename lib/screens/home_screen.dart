import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/chat_provider.dart';
import 'calendar_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Add sample events when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarProvider = context.read<CalendarProvider>();
      final chatProvider = context.read<ChatProvider>();

      // Set up the connection between chat and calendar providers
      chatProvider.setCalendarProvider(calendarProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const CalendarChatScreen();
  }
}
