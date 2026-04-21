import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/glow_up_local_data_source.dart';
import 'glow_up_event.dart';
import 'glow_up_state.dart';

class GlowUpBloc extends Bloc<GlowUpEvent, GlowUpState> {
  final GlowUpLocalDataSource dataSource;

  GlowUpBloc({required this.dataSource}) : super(GlowUpInitial()) {
    on<LoadGlowUpHistoryEvent>(_onLoad);
    on<ClearGlowUpHistoryEvent>(_onClear);
  }

  Future<void> _onLoad(LoadGlowUpHistoryEvent event, Emitter<GlowUpState> emit) async {
    emit(GlowUpLoading());
    try {
      final entries = await dataSource.getAllEntries();

      if (entries.isEmpty) {
        emit(const GlowUpLoaded(
          entries: [],
          statusMessage: 'No scans yet. Analyze your face to start tracking!',
        ));
        return;
      }

      double? improvement;
      String statusMessage;

      if (entries.length >= 2) {
        // entries[0] is newest, entries[last] is oldest
        final newest = entries.first.overallScore;
        final oldest = entries.last.overallScore;
        improvement = newest - oldest;

        if (improvement > 2) {
          statusMessage = 'You improved by +${improvement.toStringAsFixed(1)}% 📈🔥';
        } else if (improvement < -2) {
          statusMessage = 'Score dipped by ${improvement.toStringAsFixed(1)}%. Keep going! 💪';
        } else {
          statusMessage = 'Your symmetry is stable. Consistency is key! ⚖️';
        }
      } else {
        statusMessage = 'Keep scanning to track your glow-up over time! ✨';
      }

      emit(GlowUpLoaded(
        entries: entries,
        improvement: improvement,
        statusMessage: statusMessage,
      ));
    } catch (e) {
      emit(GlowUpError('Failed to load history: $e'));
    }
  }

  Future<void> _onClear(ClearGlowUpHistoryEvent event, Emitter<GlowUpState> emit) async {
    await dataSource.clearAll();
    emit(const GlowUpLoaded(
      entries: [],
      statusMessage: 'History cleared. Start fresh! 🌟',
    ));
  }
}
