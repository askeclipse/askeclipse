import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../generated/languages/index.dart';
import '../../models/app_model.dart';
import '../../models/entities/user.dart';
import '../../models/notification_model.dart';
import '../../services/dependency_injection.dart';
import '../../widgets/common/splash_screen.dart';
import 'config/theme.dart';
import 'login_screen/login_screen.dart';
import 'models/authentication_model.dart';
import 'models/delivery_order_model.dart';
import 'models/delivery_order_stat_model.dart';
import 'models/map_model.dart';
import 'models/notification_model.dart' as delivery_notification;
import 'screen_index.dart';
import 'services/delivery.dart';

class DeliveryApp extends StatefulWidget {
  final String? locale;
  final User? user;
  final bool isFromMV;

  const DeliveryApp({
    Key? key,
    this.user,
    this.locale,
    this.isFromMV = false,
  }) : super(key: key);

  @override
  State<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends State<DeliveryApp> with WidgetsBindingObserver {
  final _notificationModel = NotificationModel();
  late final _appModel;

  @override
  void initState() {
    final deliveryService = DeliveryService(
      domain: serverConfig['url'],
      consumerKey: serverConfig['consumerKey'],
      consumerSecret: serverConfig['consumerSecret'],
    );
    injector.registerSingleton<DeliveryService>(deliveryService);
    if (!widget.isFromMV) {
      _appModel = AppModel();
      _appModel.getPrefConfig();
      // model.loadAppConfig();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user != null) {
      return ChangeNotifierProvider<DeliveryAuthenticationModel>(
        create: (context) => DeliveryAuthenticationModel(user: widget.user),
        child: Consumer2<AppModel, DeliveryAuthenticationModel>(
          builder: (context, model, model2, _) {
            return MaterialApp(
              theme: ColorsConfig.getTheme(context, model.darkTheme),
              debugShowCheckedModeBanner: false,
              locale: Locale(model.langCode, ''),
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
                LocalWidgetLocalizations.delegate,
                SubMaterialLocalizations.delegate,
                SubCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: Scaffold(
                body: MultiProvider(
                  providers: [
                    ChangeNotifierProvider<DeliveryStatModel>(
                      create: (_) => DeliveryStatModel(
                        model2.user,
                      ),
                      lazy: false,
                    ),
                    ChangeNotifierProvider<
                        delivery_notification.NotificationModel>(
                      create: (_) => delivery_notification.NotificationModel(
                        model2.user!,
                      ),
                    ),
                    ChangeNotifierProvider<DeliveryOrderModel>(
                      create: (_) => DeliveryOrderModel(
                        model2.user,
                      ),
                      lazy: false,
                    ),
                    ChangeNotifierProvider<MapModel>(
                      create: (_) => MapModel(),
                      lazy: false,
                    ),
                    ChangeNotifierProvider<
                        delivery_notification.NotificationModel>(
                      create: (_) => delivery_notification.NotificationModel(
                        model2.user!,
                      ),
                      lazy: false,
                    ),
                  ],
                  child: ScreenIndex(isFromMV: widget.isFromMV),
                ),
              ),
            );
          },
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppModel>.value(value: _appModel),
        ChangeNotifierProvider<DeliveryAuthenticationModel>(
            create: (_) => DeliveryAuthenticationModel()),
      ],
      child: Consumer<AppModel>(
        builder: (context, appModel, _) {
          var languageCode = appModel.langCode.isEmptyOrNull
              ? kAdvanceConfig.defaultLanguage
              : appModel.langCode.toString();
          var countryCode = '';

          if (languageCode.contains('_')) {
            countryCode = languageCode.substring(languageCode.indexOf('_') + 1);
            languageCode =
                languageCode.substring(0, languageCode.indexOf(('_')));
          }
          return MaterialApp(
            theme: ColorsConfig.getTheme(context, appModel.darkTheme),
            debugShowCheckedModeBanner: false,
            locale: Locale(languageCode, countryCode),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              LocalWidgetLocalizations.delegate,
              SubMaterialLocalizations.delegate,
              SubCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return SplashScreenIndex(
                    imageUrl: kSplashScreen['image'],
                    splashScreenType: kSplashScreen['type'],
                    actionDone: () => Navigator.of(context)
                        .pushReplacement(CupertinoPageRoute(
                      builder: (BuildContext context) =>
                          Consumer<DeliveryAuthenticationModel>(
                        builder: (context, model2, _) =>
                            LayoutBuilder(builder: (context, _) {
                          if (model2.state !=
                              DeliveryAuthenticationModelState.loggedIn) {
                            return DeliveryLoginScreen();
                          }
                          return MultiProvider(providers: [
                            ChangeNotifierProvider<DeliveryStatModel>(
                              create: (_) => DeliveryStatModel(
                                model2.user,
                              ),
                              lazy: false,
                            ),
                            ChangeNotifierProvider<
                                delivery_notification.NotificationModel>(
                              create: (_) =>
                                  delivery_notification.NotificationModel(
                                model2.user!,
                              ),
                            ),
                            ChangeNotifierProvider<DeliveryOrderModel>(
                              create: (_) => DeliveryOrderModel(
                                model2.user,
                              ),
                              lazy: false,
                            ),
                            ChangeNotifierProvider<MapModel>(
                              create: (_) => MapModel(),
                              lazy: false,
                            ),
                            ChangeNotifierProvider<
                                delivery_notification.NotificationModel>(
                              create: (_) =>
                                  delivery_notification.NotificationModel(
                                model2.user!,
                              ),
                              lazy: false,
                            ),
                          ], child: ScreenIndex(isFromMV: widget.isFromMV));
                        }),
                      ),
                    )),
                    key: const Key('SplashScreenIndex'),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _notificationModel.checkGranted();
    }
  }
}
