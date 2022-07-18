import 'package:flutter/material.dart';

class InfoWidget extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final style;
  final VoidCallback? onCallBack;

  const InfoWidget({
    Key? key,
    required this.title,
    required this.content,
    required this.icon,
    this.style,
    this.onCallBack,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onCallBack,
      child: Container(
        margin: const EdgeInsets.only(top: 5.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.0,
              color: Colors.grey,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyText2!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.4),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    content,
                    style: style ?? theme.textTheme.headline6,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
