import 'package:flutter/material.dart';
import '../../../../../common/config.dart';
import '../../../../../generated/l10n.dart';

class CurrentStatus extends StatelessWidget {
  final String status;
  const CurrentStatus({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((serverConfig['platform'] != null &&
            serverConfig['platform'] != 'wcfm') ||
        status == 'publish' ||
        status.isEmpty ||
        (kVendorConfig['DisablePendingProduct'] ?? false)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        S.of(context).yourProductIsUnderReview,
        style: Theme.of(context).textTheme.caption!.copyWith(color: Colors.red),
      ),
    );
  }
}
