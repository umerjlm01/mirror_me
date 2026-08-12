import 'package:equatable/equatable.dart';

class UserIntentEntity extends Equatable {
  final String goal;
  final String preference;
  final String glasses;

  const UserIntentEntity({
    required this.goal,
    required this.preference,
    required this.glasses,
  });

  static const UserIntentEntity defaults = UserIntentEntity(
    goal: 'Look sharper',
    preference: 'Professional',
    glasses: 'Open to suggestions',
  );

  @override
  List<Object?> get props => [goal, preference, glasses];
}
