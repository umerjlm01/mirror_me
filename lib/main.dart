import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'core/constants/app_colors.dart';
import 'features/face_analysis/presentation/bloc/face_analysis_bloc.dart';
import 'features/face_analysis/presentation/pages/splash_screen.dart';
import 'features/glow_up/presentation/bloc/glow_up_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();
  runApp(const MirrorMeApp());
}

class MirrorMeApp extends StatelessWidget {
  const MirrorMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FaceAnalysisBloc>(
          create: (_) => di.sl<FaceAnalysisBloc>(),
        ),
        BlocProvider<GlowUpBloc>(
          create: (_) => di.sl<GlowUpBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'MirrorMe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: AppColors.backgroundDark,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
