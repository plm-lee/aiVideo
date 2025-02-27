import 'package:flutter/cupertino.dart';

class DialogUtils {
  static void showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop();
                onPressed?.call();
              },
            ),
          ],
        );
      },
    );
  }

  static void showSuccess({
    required BuildContext context,
    String title = 'Success',
    required String content,
    VoidCallback? onPressed,
  }) {
    showAlert(
      context: context,
      title: title,
      content: content,
      onPressed: onPressed,
    );
  }

  static void showError({
    required BuildContext context,
    String title = 'Error',
    required String content,
    VoidCallback? onPressed,
  }) {
    showAlert(
      context: context,
      title: title,
      content: content,
      onPressed: onPressed,
    );
  }
}
