import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:recurly_analytics/api.dart';
import 'package:recurly_analytics/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:recurly_analytics/billing_page.dart';
import 'package:recurly_analytics/login_page.dart';
import 'package:recurly_analytics/mrr_page.dart';
import 'package:recurly_analytics/subscribers_page.dart';
import 'package:flutter_redux_navigation/flutter_redux_navigation.dart';

void main() {
  final store = new Store<AppState>(stateReducer,
      initialState: AppState.initial(),
      middleware: [
        AppMiddleware(RecurlyApi()),
        NavigationMiddleware<AppState>(),
      ]);

  runApp(new MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  final routes = <String, WidgetBuilder>{
    LoginPage.tag: (context) => LoginPage(),
    BillingPage.tag: (context) => BillingPage(),
    MRRPage.tag: (context) => MRRPage(),
    SubscribersPage.tag: (context) => SubscribersPage()
  };

  MyApp({this.store}) : super();

  @override
  Widget build(BuildContext context) {
    return new StoreProvider<AppState>(
      store: store,
      child: new MaterialApp(
        title: 'Recurly Analytics',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        navigatorKey: NavigatorHolder.navigatorKey,
        onGenerateRoute: _getRoute,
        home: new LoginPage(),
        routes: routes
      ),
    );}

  Route _getRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _buildRoute(settings, LoginPage());
      case '/billing':
        return _buildRoute(settings, BillingPage());
      case '/mrr':
        return _buildRoute(settings, MRRPage());
      case '/subscribers':
        return _buildRoute(settings, SubscribersPage());
      default:
        return _buildRoute(settings, LoginPage());
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) {
    return new MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) => builder,
    );
  }
}
