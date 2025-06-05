import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../models/calendar_event.dart';
import '../models/chat_message.dart';
import 'calendar_provider.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  CalendarProvider? _calendarProvider;
  String? _currentFunction;
  String _loadingStatus = 'AI is typing...';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentFunction => _currentFunction;
  String get loadingStatus => _loadingStatus;

  ChatProvider() {
    _geminiService.setFunctionCallCallback(_setCurrentFunction);
  }

  // Set calendar provider to enable event creation
  void setCalendarProvider(CalendarProvider calendarProvider) {
    _calendarProvider = calendarProvider;
    _geminiService.setEventAddedCallback(_onEventAdded);
    _geminiService.setFunctionCallCallback(_setCurrentFunction);
  }

  void _onEventAdded(CalendarEvent event) {
    _calendarProvider?.addEvent(event.startTime, event);
  }

  void _updateLoadingStatus(String status) {
    _loadingStatus = status;
    notifyListeners();
  }

  void _setCurrentFunction(String? functionName) {
    _currentFunction = functionName;
    if (functionName != null) {
      switch (functionName) {
        case 'add_schedule':
          _updateLoadingStatus('Creating calendar event...');
          break;
        case 'get_current_time':
          _updateLoadingStatus('Getting current time...');
          break;
        default:
          _updateLoadingStatus('Processing request...');
      }
    } else {
      _updateLoadingStatus('AI is typing...');
    }
  }

  Future<void> sendMessage(String message) async {
    // Add user message
    _messages.add(
      ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _geminiService.sendMessage(message);

      // Add AI response
      _messages.add(
        ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    } catch (e) {
      _error = 'Failed to get AI response: $e';
    } finally {
      _isLoading = false;
      _currentFunction = null;
      notifyListeners();
    }
  }

  Future<void> getCalendarHelp(String message) async {
    // Add user message
    _messages.add(
      ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _geminiService.getCalendarHelp(message);

      // Add AI response
      _messages.add(
        ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    } catch (e) {
      _error = 'Failed to get calendar help: $e';
    } finally {
      _isLoading = false;
      _currentFunction = null;
      notifyListeners();
    }
  }

  void startNewSession() {
    _messages.clear();
    _error = null;
    _geminiService.startNewSession();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
