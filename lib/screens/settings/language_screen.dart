import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/app_model.dart';
import '../../services/service_config.dart';
import '../common/app_bar_mixin.dart';

class LanguageScreen extends StatefulWidget {
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with AppBarMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _showLoading(String language) {
    final snackBar = SnackBar(
      content: Text(
        S.of(context).languageSuccess,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Theme.of(context).primaryColor,
      action: SnackBarAction(
        label: language,
        onPressed: () {},
      ),
    );

    _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    var list = <Widget>[];
    var languages = getLanguages(this.context);

    for (var i = 0; i < languages.length; i++) {
      if (Config().isVendorManagerType()) {
        if (Configurations.unsupportedLanguages
            .contains(languages[i]['code'])) {
          continue;
        }
      }
      list.add(
        ListTile(
          leading: Image.asset(
            languages[i]['icon'],
            width: 30,
            height: 20,
            fit: BoxFit.cover,
          ),
          title: Text(languages[i]['name']),
          onTap: () {
            Provider.of<AppModel>(context, listen: false)
                .changeLanguage(languages[i]['code'], context)
                .then((value) {
              setState(() {});
              _showLoading(languages[i]['text']);
            });
          },
        ),
      );
      if (i < languages.length - 1) {
        list.add(
          Divider(
            color: Theme.of(context).primaryColorLight,
            height: 1.0,
            indent: 75,
            //endIndent: 20,
          ),
        );
      }
    }

    return renderScaffold(
      routeName: RouteList.language,
      body: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            title: Text(
              S.of(context).language,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            leading: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                ...list,
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
