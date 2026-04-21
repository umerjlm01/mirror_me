import 'package:equatable/equatable.dart';
import '../../domain/entities/glow_up_entry_entity.dart';

abstract class GlowUpState extends Equatable {
  const GlowUpState();
  @override
  List<Object?> get props => [];
}

class GlowUpInitial extends GlowUpState {}

class GlowUpLoading extends GlowUpState {}

class GlowUpLoaded extends GlowUpState {
  final List<GlowUpEntryEntity> entries;
  final double? improvement; // null if only one entry
  final String statusMessage;

  const GlowUpLoaded({
    required this.entries,
    this.improvement,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [entries, improvement, statusMessage];
}

class GlowUpError extends GlowUpState {
  final String message;
  const GlowUpError(this.message);
  @override
  List<Object?> get props => [message];
}
