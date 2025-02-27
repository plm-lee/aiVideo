import 'package:flutter/cupertino.dart';

class DialogUtils {
  static void showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    bool autoDismiss = false,
    VoidCallback? onDismissed,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        if (autoDismiss) {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            onDismissed?.call();
          });
        }

        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: autoDismiss
              ? [] // 自动关闭时不显示按钮
              : <Widget>[
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
    bool autoDismiss = false,
    VoidCallback? onDismissed,
  }) {
    showAlert(
      context: context,
      title: title,
      content: content,
      onPressed: onPressed,
      autoDismiss: autoDismiss,
      onDismissed: onDismissed,
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
