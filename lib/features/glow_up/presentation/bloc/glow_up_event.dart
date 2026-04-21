import 'package:equatable/equatable.dart';

abstract class GlowUpEvent extends Equatable {
  const GlowUpEvent();
  @override
  List<Object?> get props => [];
}

class LoadGlowUpHistoryEvent extends GlowUpEvent {}

class ClearGlowUpHistoryEvent extends GlowUpEvent {}
