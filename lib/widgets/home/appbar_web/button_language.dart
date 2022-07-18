import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../models/app_model.dart';
import '../../../screens/base_screen.dart';
import '../../../services/service_config.dart';

class ButtonChooseLanguage extends StatefulWidget {
  final TextStyle? style;
  final double width;
  const ButtonChooseLanguage({Key? key, this.style, this.width = 95})
      : super(key: key);

  @override
  State<ButtonChooseLanguage> createState() => _ButtonChooseLanguageState();
}

class _ButtonChooseLanguageState extends BaseScreen<ButtonChooseLanguage> {
  var dropdownValue = <dynamic, dynamic>{};
  @override
  void afterFirstLayout(BuildContext context) {
    initApp();
    super.afterFirstLayout(context);
  }

  void onChanged(Map? lang) async {
    if (lang != null) {
      await Provider.of<AppModel>(context, listen: false)
          .changeLanguage(lang['code'], context);

      WidgetsBinding.instance.addPostFrameCallback((_) => initApp());
    }
  }

  var listLanguage = <Map<dynamic, dynamic>>[];

  void initApp() async {
    var languages = getLanguages(context);
    listLanguage.clear();

    for (var i = 0; i < languages.length; i++) {
      if (Config().isVendorManagerType()) {
        if (Configurations.unsupportedLanguages
            .contains(languages[i]['code'])) {
          continue;
        }
      }
      if (Provider.of<AppModel>(context, listen: false).langCode ==
          languages[i]['code']) {
        dropdownValue = languages[i];
      }

      listLanguage.add(languages[i]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Map>(
      key: ValueKey('${listLanguage.length}${dropdownValue['text']}'),
      value: dropdownValue,
      onChanged: onChanged,
      items: List.generate(
        listLanguage.length,
        (index) => DropdownMenuItem<Map>(
          value: listLanguage[index],
          child: SizedBox(
            width: widget.width,
            child: Row(
              children: [
                Image.asset(listLanguage[index]['icon'],
                    width: 30,
                    height: 20,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                  return const SizedBox(width: 30, height: 20);
                }),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(
                  listLanguage[index]['text'],
                  style: widget.style,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
