import 'dart:async';
import 'package:async/async.dart';
import 'package:redux/redux.dart';
import 'package:recurly_analytics/api.dart';

// store

class AppState {
  final String subdomain;
  final String cookie;
  final bool hasError;
  final bool isLoading;
  final Map stats;

  AppState({
    this.subdomain,
    this.cookie,
    this.stats,
    this.hasError = false,
    this.isLoading = false
  });

  factory AppState.initial() => new AppState(cookie: "", stats: new Map());

  factory AppState.loading() => AppState(isLoading: true);

  factory AppState.error() => AppState(hasError: true);

  factory AppState.handleCookie(String cookie, String subdomain) => AppState(cookie: cookie, subdomain: subdomain, isLoading: false);
}

// actions

class GetCookieAction {
  final String email;
  final String password;

  GetCookieAction(
    this.email,
    this.password
  );
}

class GetStatsAction {}

class LoadingAction {}

class ErrorAction {}

class HandleCookieAction {
  final String cookie;
  final String subdomain;

  HandleCookieAction(this.cookie, this.subdomain);
}

class HandleStatsAction {
  final Map stats;

  HandleStatsAction(this.stats);
}

// reducer

final stateReducer = combineReducers<AppState>([
  TypedReducer<AppState, LoadingAction>(_onLoad),
  TypedReducer<AppState, ErrorAction>(_onError),
  TypedReducer<AppState, HandleCookieAction>(_onReturnCookie),
  TypedReducer<AppState, HandleStatsAction>(_onReturnStats)
]);

AppState _onLoad(AppState state, LoadingAction action) => AppState.loading();

AppState _onError(AppState state, ErrorAction action) => AppState.error();

AppState _onReturnCookie(AppState state, HandleCookieAction action) => AppState.handleCookie(action.cookie, action.subdomain);

AppState _onReturnStats(AppState state, HandleStatsAction action) => AppState(cookie: state.cookie, stats: action.stats, isLoading: false);

// middleware

class AppMiddleware implements MiddlewareClass<AppState> {
  final RecurlyApi api;

  Timer _timer;
  CancelableOperation<Store<AppState>> _operation;

  AppMiddleware(this.api);

  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) {
    if (action is GetCookieAction) {
      // Stop our previous debounce timer and search.
      _timer?.cancel();
      _operation?.cancel();

      // Don't start searching until the user pauses for 250ms. This will stop
      // us from over-fetching from our backend.
      _timer = new Timer(new Duration(milliseconds: 250), () {
        store.dispatch(LoadingAction());

        print("dispatched getCookieAction");

        // Instead of a simple Future, we'll use a CancellableOperation from the
        // `async` package. This will allow us to cancel the previous operation
        // if a new Search term comes in. This will prevent us from
        // accidentally showing stale results.
        _operation = CancelableOperation.fromFuture(api
            .getToken(action.email, action.password)
            .then((result) => store..dispatch(HandleCookieAction(result['cookie'], result['subdomain'])))
            .catchError((e, s) => store..dispatch(ErrorAction())));
      });
    }

    // Make sure to forward actions to the next middleware in the chain!
    next(action);
  }
}