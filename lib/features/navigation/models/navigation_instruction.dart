
class NavigationInstruction {
  final int type;
  final String instruction;
  final String verbalInstruction;
  final double distanceMeters;
  final double durationSeconds;
  final int beginShapeIndex;
  final int endShapeIndex;

  const NavigationInstruction({
    required this.type,
    required this.instruction,
    required this.verbalInstruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.beginShapeIndex,
    required this.endShapeIndex,
  });
}
