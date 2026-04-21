// lib/widgets/agent_guide_fab.dart
// Permanent floating button that opens the Agent Guide (Amy).
// Injected via MaterialApp.builder so it appears above every screen
// without modifying any existing screen code.

import 'package:flutter/material.dart';

/// Observer that tracks the current route name so the FAB can hide
/// itself on certain screens (login, onboarding, the agent itself).
class AgentGuideRouteTracker extends NavigatorObserver {
  static final AgentGuideRouteTracker instance = AgentGuideRouteTracker._();
  AgentGuideRouteTracker._();

  /// Root navigator key — used by the FAB (which sits above the
  /// Navigator in the widget tree via MaterialApp.builder) so it
  /// can still push a new route.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  void _update(Route<dynamic>? route) {
    currentRoute.value = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }
}

class AgentGuideFab extends StatelessWidget {
  const AgentGuideFab({super.key});

  static const String _avatarAsset = 'assets/univers_visuel/agent_guide.png';

  /// Routes where the FAB should stay hidden.
  static const Set<String> _hiddenRoutes = {
    '/login',
    '/email',
    '/onboarding',
    '/change-password',
    '/agent-guide',
  };

  bool _shouldShow(String? routeName) {
    // routeName null/'/' = initial splash/intro — show the FAB.
    if (routeName == null || routeName == '/') return true;
    return !_hiddenRoutes.contains(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AgentGuideRouteTracker.instance.currentRoute,
      builder: (context, routeName, _) {
        if (!_shouldShow(routeName)) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 16,
          bottom: 20,
          child: SafeArea(
            child: _FabButton(avatarAsset: _avatarAsset),
          ),
        );
      },
    );
  }
}

class _FabButton extends StatelessWidget {
  final String avatarAsset;
  const _FabButton({required this.avatarAsset});

  void _open(BuildContext context) {
    AgentGuideRouteTracker.rootNavigatorKey.currentState
        ?.pushNamed('/agent-guide');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open your guide Amy',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: Image.asset(
                avatarAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE0E7FF),
                  child: const Icon(
                    Icons.support_agent,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
