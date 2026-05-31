enum ChatDensity {
  compact,
  normal,
  comfortable,
}

class MessageDisplaySettings {
  final double messageFontSize;
  final ChatDensity density;
  final bool showMessageTime;
  final bool showTechnicalIds;

  const MessageDisplaySettings({
    required this.messageFontSize,
    required this.density,
    required this.showMessageTime,
    required this.showTechnicalIds,
  });

  static const defaults = MessageDisplaySettings(
    messageFontSize: 14,
    density: ChatDensity.normal,
    showMessageTime: true,
    showTechnicalIds: true,
  );

  MessageDisplaySettings copyWith({
    double? messageFontSize,
    ChatDensity? density,
    bool? showMessageTime,
    bool? showTechnicalIds,
  }) {
    return MessageDisplaySettings(
      messageFontSize: messageFontSize ?? this.messageFontSize,
      density: density ?? this.density,
      showMessageTime: showMessageTime ?? this.showMessageTime,
      showTechnicalIds: showTechnicalIds ?? this.showTechnicalIds,
    );
  }

  double get verticalMessagePadding => switch (density) {
        ChatDensity.compact => 6,
        ChatDensity.normal => 10,
        ChatDensity.comfortable => 14,
      };

  double get horizontalMessagePadding => switch (density) {
        ChatDensity.compact => 10,
        ChatDensity.normal => 14,
        ChatDensity.comfortable => 18,
      };

  double get messageSpacing => switch (density) {
        ChatDensity.compact => 3,
        ChatDensity.normal => 6,
        ChatDensity.comfortable => 9,
      };
}
