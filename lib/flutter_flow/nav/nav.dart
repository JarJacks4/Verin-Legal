import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';
import '/verin_app/admin/admin_shell.dart' show AdminNav;
import '/verin_app/pages.dart';
import '/verin_app/widgets/atoms.dart' show kBrandNavy;
import '/verin_app/widgets/motion.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? const VMattersPage()
          : const VWelcomePage(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? const VMattersPage()
              : const VWelcomePage(),
        ),
        FFRoute(
          name: CreateAccount1Widget.routeName,
          path: CreateAccount1Widget.routePath,
          builder: (context, params) => CreateAccount1Widget(),
        ),
        FFRoute(
          name: FirmWorkspaceSignInWidget.routeName,
          path: FirmWorkspaceSignInWidget.routePath,
          builder: (context, params) => const VSignInPage(),
        ),
        FFRoute(
          name: MattersListWidget.routeName,
          path: MattersListWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VMattersPage(),
        ),
        FFRoute(
          name: 'Annotations',
          path: '/annotations',
          requireAuth: true,
          builder: (context, params) => const VAnnotationsPage(),
        ),
        FFRoute(
          name: 'GettingStarted',
          path: '/getting-started',
          requireAuth: true,
          builder: (context, params) => const VOnboardingPage(),
        ),
        FFRoute(
          name: ReviewQueueWidget.routeName,
          path: ReviewQueueWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VReviewPage(),
        ),
        FFRoute(
          name: AdminDashBoardPageWidget.routeName,
          path: AdminDashBoardPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.dashboard),
        ),
        FFRoute(
          name: AdminMattersListWidget.routeName,
          path: AdminMattersListWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.matters),
        ),
        FFRoute(
          name: AdminBillingAndPlanWidget.routeName,
          path: AdminBillingAndPlanWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.billing),
        ),
        FFRoute(
          name: AdminTeamsWidget.routeName,
          path: AdminTeamsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.team),
        ),
        FFRoute(
          name: AdminProgramPageWidget.routeName,
          path: AdminProgramPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.program),
        ),
        FFRoute(
          name: WelcomeScreenWidget.routeName,
          path: WelcomeScreenWidget.routePath,
          builder: (context, params) => const VWelcomePage(),
        ),
        FFRoute(
          name: CreatePasswordScreenWidget.routeName,
          path: CreatePasswordScreenWidget.routePath,
          builder: (context, params) => CreatePasswordScreenWidget(),
        ),
        FFRoute(
          name: MattersTabGroupHomeWidget.routeName,
          path: MattersTabGroupHomeWidget.routePath,
          requireAuth: true,
          asyncParams: {
            'matterDoc': getDoc(['Matters'], MattersRecord.fromSnapshot),
          },
          builder: (context, params) => VMatterPage(
            matter: params.getParam<MattersRecord>(
              'matterDoc',
              ParamType.Document,
            ),
            fromAdmin: params.getParam<String>('from', ParamType.String) == 'admin',
            initialTab: params.getParam<String>('tab', ParamType.String) ?? '',
          ),
        ),
        FFRoute(
          name: SampleWidget.routeName,
          path: SampleWidget.routePath,
          requireAuth: true,
          builder: (context, params) => SampleWidget(),
        ),
        FFRoute(
          name: CreateAccountStep1Widget.routeName,
          path: CreateAccountStep1Widget.routePath,
          builder: (context, params) => VSignUpPage(step: 1, invite: params.getParam<String>('invite', ParamType.String) ?? ''),
        ),
        FFRoute(
          name: CreateAccountStep2Widget.routeName,
          path: CreateAccountStep2Widget.routePath,
          builder: (context, params) => const VSignUpPage(step: 2),
        ),
        FFRoute(
          name: FirmSettingsWidget.routeName,
          path: FirmSettingsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VAdminPage(nav: AdminNav.settings),
        ),
        FFRoute(
          name: ClioCallbackPageWidget.routeName,
          path: ClioCallbackPageWidget.routePath,
          builder: (context, params) => ClioCallbackPageWidget(
            code: params.getParam(
              'code',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: SmokeballCallbackPageCopyWidget.routeName,
          path: SmokeballCallbackPageCopyWidget.routePath,
          builder: (context, params) => SmokeballCallbackPageCopyWidget(
            code: params.getParam(
              'code',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: MyCaseCallbackPageWidget.routeName,
          path: MyCaseCallbackPageWidget.routePath,
          builder: (context, params) => MyCaseCallbackPageWidget(
            code: params.getParam(
              'code',
              ParamType.String,
            ),
          ),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/firmWorkspaceSignIn';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          // While auth resolves, the launch splash (VSplashOverlay) covers
          // the app; this is just its backdrop.
          final child = appStateNotifier.loading
              ? const ColoredBox(color: kBrandNavy, child: SizedBox.expand())
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: VMotion.page,
                  reverseTransitionDuration: VMotion.pageReverse,
                  transitionsBuilder: vPageTransition,
                );
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
