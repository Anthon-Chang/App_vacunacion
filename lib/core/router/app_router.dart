import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/cambiar_password_screen.dart';
import '../../presentation/screens/auth/recuperar_password_screen.dart';
import '../../presentation/screens/coordinador_campana/dashboard_campana_screen.dart';
import '../../presentation/screens/coordinador_campana/sectores/sectores_screen.dart';
import '../../presentation/screens/coordinador_campana/sectores/form_sector_screen.dart';
import '../../presentation/screens/coordinador_campana/brigada/coordinadores_screen.dart';
import '../../presentation/screens/coordinador_campana/brigada/form_coordinador_screen.dart';
import '../../presentation/screens/coordinador_brigada/dashboard_brigada_screen.dart';
import '../../presentation/screens/coordinador_brigada/vacunadores/vacunadores_screen.dart';
import '../../presentation/screens/coordinador_brigada/vacunadores/form_vacunador_screen.dart';
import '../../presentation/screens/coordinador_brigada/registros/registros_sector_screen.dart';
import '../../presentation/screens/vacunador/dashboard_vacunador_screen.dart';
import '../../presentation/screens/vacunador/form_vacunacion_screen.dart';
import '../../presentation/screens/vacunador/mis_registros_screen.dart';
import '../../presentation/screens/dashboard/dashboard_estadisticas_screen.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../domain/entities/vacunacion.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      return authState.when(
        data: (user) {
          final rutasPublicas = ['/login', '/recuperar-password'];
          final esRutaPublica = rutasPublicas.contains(state.matchedLocation);
          if (user == null && !esRutaPublica) return '/login';
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      );
    },
    routes: [
      // Auth
      GoRoute(path: '/login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/cambiar-password',
          builder: (_, __) => const CambiarPasswordScreen()),
      GoRoute(path: '/recuperar-password',
          builder: (_, __) => const RecuperarPasswordScreen()),

      // Coordinador campaña
      GoRoute(path: '/dashboard-campana',
          builder: (_, __) => const DashboardCampanaScreen()),
      GoRoute(path: '/sectores',
          builder: (_, __) => const SectoresScreen()),
      GoRoute(path: '/sectores/nuevo',
          builder: (_, __) => const FormSectorScreen()),
      GoRoute(path: '/sectores/editar/:id',
          builder: (_, state) => FormSectorScreen(
              sectorEditar: state.extra as dynamic)),
      GoRoute(path: '/coordinadores',
          builder: (_, __) => const CoordinadoresScreen()),
      GoRoute(path: '/coordinadores/nuevo',
          builder: (_, __) => const FormCoordinadorScreen()),

      // Coordinador brigada
      GoRoute(path: '/dashboard-brigada',
          builder: (_, __) => const DashboardBrigadaScreen()),
      // nuevo ANTES que :sectorId para evitar conflicto
      GoRoute(path: '/vacunadores/nuevo',
          builder: (_, state) => FormVacunadorScreen(
              sectorIdInicial: state.extra as String?)),
      GoRoute(path: '/vacunadores/:sectorId',
          builder: (_, state) => VacunadoresScreen(
              sectorId: state.pathParameters['sectorId']!)),
      GoRoute(path: '/registros-sector/:sectorId',
          builder: (_, state) => RegistrosSectorScreen(
              sectorId: state.pathParameters['sectorId']!)),

      // Vacunador
      GoRoute(path: '/dashboard-vacunador',
          builder: (_, __) => const DashboardVacunadorScreen()),
      GoRoute(path: '/nueva-vacunacion',
          builder: (_, __) => const FormVacunacionScreen()),
      GoRoute(path: '/editar-vacunacion/:id',
          builder: (_, state) => FormVacunacionScreen(
              vacunacionEditar: state.extra as Vacunacion?)),
      GoRoute(path: '/mis-registros/:vacunadorId',
          builder: (_, state) => MisRegistrosScreen(
              vacunadorId: state.pathParameters['vacunadorId']!)),

      // Dashboard estadísticas
      GoRoute(path: '/dashboard-estadisticas',
          builder: (_, __) => const DashboardEstadisticasScreen()),
    ],
  );
});