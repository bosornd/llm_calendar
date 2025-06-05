import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/calendar_event.dart';

class GeminiService {
  static GenerativeModel? _model;
  static ChatSession? _chat;
  Function(CalendarEvent)? _onEventAdded;
  Function(String?)? _onFunctionCall; // Callback for function call status

  // Callback to set event addition handler
  void setEventAddedCallback(Function(CalendarEvent) callback) {
    _onEventAdded = callback;
  }

  // Callback to set function call status handler
  void setFunctionCallCallback(Function(String?) callback) {
    _onFunctionCall = callback;
  }

  GenerativeModel get model {
    if (_model == null) {
      final apiKey = dotenv.env['GOOGLE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GOOGLE_API_KEY not found in environment variables');
      }

      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        tools: [
          Tool(
            functionDeclarations: [
              FunctionDeclaration(
                'add_schedule',
                'Add a new event to the calendar',
                Schema(
                  SchemaType.object,
                  properties: {
                    'title': Schema(
                      SchemaType.string,
                      description: 'Event title',
                    ),
                    'startTime': Schema(
                      SchemaType.string,
                      description:
                          'Start time in ISO 8601 format (e.g., 2024-01-15T14:30:00)',
                    ),
                    'duration': Schema(
                      SchemaType.integer,
                      description:
                          'Duration in minutes (optional, defaults to 60 minutes)',
                    ),
                    'isAllDay': Schema(
                      SchemaType.boolean,
                      description:
                          'Whether the event is all day (optional, defaults to false)',
                    ),
                  },
                  requiredProperties: ['title', 'startTime'],
                ),
              ),
              FunctionDeclaration(
                'get_current_time',
                'Get the current date and time. MUST be called when users mention relative time (today, tomorrow, next week, this afternoon, etc.), ask about scheduling, or need temporal context for any calendar operations.',
                Schema(
                  SchemaType.object,
                  properties: {},
                  requiredProperties: [],
                ),
              ),
            ],
          ),
        ],
        systemInstruction: Content.system(
          'You are a helpful AI assistant integrated with a calendar application. '
          'You can help users with scheduling, reminders, and general questions. '
          'When users ask about calendar-related tasks, provide helpful suggestions '
          'and guidance. Keep your responses concise and friendly. '
          '\n'
          'IMPORTANT: Always use the get_current_time function FIRST when users mention: '
          '- Relative time expressions (today, tomorrow, next week, this afternoon, etc.) '
          '- Specific times without dates (2pm, 3:30, morning, evening) '
          '- Date-related questions (what day is it, what time is it) '
          '- Scheduling requests (schedule a meeting, book an appointment) '
          '- Any time-sensitive queries '
          '\n'
          'When users ask to create an event or schedule something, ALWAYS: '
          '1. First call get_current_time to understand the current context '
          '2. Then use the add_schedule function with proper ISO 8601 format '
          'The duration parameter is optional and defaults to 60 minutes (1 hour). '
          'You can adjust the duration based on the user\'s request (e.g., 30 minutes for a quick meeting, 120 minutes for a long session).',
        ),
      );
    }

    return _model!;
  }

  ChatSession get chat {
    _chat ??= model.startChat();
    return _chat!;
  }

  void startNewSession() {
    _chat = model.startChat();
  }

  String _handleGetCurrentTime() {
    final now = DateTime.now();
    final weekday =
        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][now.weekday - 1];
    final month =
        [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ][now.month - 1];

    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '$weekday, $month ${now.day}, ${now.year}';

    // Provide rich temporal context
    return 'Current date and time: $dateStr at $timeStr';
  }

  CalendarEvent _handleAddSchedule(Map<String, dynamic> args) {
    final title = args['title'] as String;
    final startTimeStr = args['startTime'] as String;
    final durationMinutes = args['duration'] as int? ?? 60; // Default 1 hour
    final isAllDay = args['isAllDay'] as bool? ?? false;

    final startTime = DateTime.parse(startTimeStr);
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: '', // Empty description for simplicity
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
    );

    // Call the callback if it's set
    _onEventAdded?.call(event);

    return event;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<String> sendMessage(String message) async {
    print('🔵 [GeminiService] Sending message: $message');

    late GenerateContentResponse response;
    try {
      response = await chat.sendMessage(Content.text(message));

      print(
        '🔵 [GeminiService] Response received. Function calls: ${response.functionCalls.length}',
      );

      // Handle function calls
      while (response.functionCalls.isNotEmpty) {
        List<FunctionResponse> functionResponses = [];

        // Process each function call
        for (final functionCall in response.functionCalls) {
          print('🔧 [GeminiService] Function called: ${functionCall.name}');

          if (functionCall.name == 'add_schedule') {
            try {
              final event = _handleAddSchedule(functionCall.args);
              final result =
                  'Successfully scheduled "${event.title}" for ${_formatDateTime(event.startTime)} to ${_formatDateTime(event.endTime)}.';
              functionResponses.add(
                FunctionResponse(functionCall.name, {'result': result}),
              );
            } catch (e) {
              functionResponses.add(
                FunctionResponse(functionCall.name, {'error': e.toString()}),
              );
            }
          } else if (functionCall.name == 'get_current_time') {
            final timeInfo = _handleGetCurrentTime();
            functionResponses.add(
              FunctionResponse(functionCall.name, {'time': timeInfo}),
            );
          }
        }

        // Otherwise, continue conversation with function responses
        print('🔵 [GeminiService] Back to model with functionResponses');
        try {
          response = await chat.sendMessage(
            Content.functionResponses(functionResponses),
          );
        } catch (e) {
          print('❌ [GeminiService] Error in follow-up: $e');
          return 'I\'m having trouble processing your request right now. Please try again.';
        }
      }

      if (response.text == null || response.text!.isEmpty) {
        print('⚠️ [GeminiService] Empty response received');
        throw Exception('Empty response from Gemini API');
      }
    } catch (e) {
      print('❌ [GeminiService] Error in sendMessage: $e');
      throw Exception('Failed to get response from Gemini: $e');
    }

    print(
      '✅ [GeminiService] Normal response: ${response.text!.substring(0, response.text!.length > 100 ? 100 : response.text!.length)}...',
    );
    return response.text!;
  }

  Future<String> getCalendarHelp(String userRequest) async {
    // Always provide current time context for calendar help
    final currentTime = _handleGetCurrentTime();

    final prompt = '''
    Current temporal context: $currentTime
    
    You are a calendar assistant. The user has made the following request: "$userRequest"
    
    Provide helpful guidance for calendar-related tasks such as:
    - Creating events
    - Setting reminders
    - Managing schedules
    - Finding available time slots
    - Organizing meetings
    
    Keep your response practical and actionable. Always consider the current date and time context provided above.
    ''';

    try {
      final content = [Content.text(prompt)];
      //      final response = await model.generateContent(content);
      final response = await chat.sendMessage(Content.text(prompt));

      // Handle function calls
      if (response.functionCalls.isNotEmpty) {
        List<FunctionResponse> functionResponses = [];
        String directResult = '';

        // Process each function call
        for (final functionCall in response.functionCalls) {
          print('🔧 [GeminiService] Function called: ${functionCall.name}');

          if (functionCall.name == 'add_schedule') {
            try {
              final event = _handleAddSchedule(functionCall.args);
              directResult =
                  'I\'ve successfully scheduled "${event.title}" for ${_formatDateTime(event.startTime)} to ${_formatDateTime(event.endTime)}.';
              functionResponses.add(
                FunctionResponse(functionCall.name, {'result': directResult}),
              );
            } catch (e) {
              directResult =
                  'I encountered an error while creating the event: ${e.toString()}';
              functionResponses.add(
                FunctionResponse(functionCall.name, {'error': e.toString()}),
              );
            }
          } else if (functionCall.name == 'get_current_time') {
            final timeInfo = _handleGetCurrentTime();
            functionResponses.add(
              FunctionResponse(functionCall.name, {'time': timeInfo}),
            );
          }
        }

        // If we have a direct result (like event creation), return it
        if (directResult.isNotEmpty) {
          return directResult;
        }

        // Otherwise, continue conversation with function responses
        try {
          //          final followUpResponse = await model.generateContent([
          //            Content.text(prompt),
          //            Content.functionResponses(functionResponses)
          //          ]);
          final followUpResponse = await chat.sendMessage(
            Content.functionResponses(functionResponses),
          );

          return followUpResponse.text ??
              'I processed your request but couldn\'t generate a proper response.';
        } catch (e) {
          print('❌ [GeminiService] Error in follow-up: $e');
          return 'I\'m having trouble processing your request right now. Please try again.';
        }
      }

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return response.text!;
    } catch (e) {
      print('❌ [GeminiService] Error in getCalendarHelp: $e');
      throw Exception('Failed to get calendar help from Gemini: $e');
    }
  }
}
