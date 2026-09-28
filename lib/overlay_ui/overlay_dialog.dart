import 'package:core_riverpod/common/color_opacity.dart';
import 'package:core_riverpod/localization/core_messages.dart';
import 'package:flutter/material.dart';

class OverlayDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final List<ButtonAction> actions;
  final bool disEnableActions;

  const OverlayDialog({
    super.key,
    this.title = "",
    this.disEnableActions = false,
    this.body = const SizedBox(),
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF1E1E1E);
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Dialog(
      backgroundColor: backgroundColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 450
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(title != "") Center(
                child: Text(title, style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600
                )),
              ),
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      child: body,
                    ),
                  ),
                ),
              ),
              if(!disEnableActions) Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(actions.isEmpty) Center(
                      child: TextButton(
                          style: ButtonStyle(
                            overlayColor: WidgetStatePropertyAll(Colors.transparent),
                            splashFactory: NoSplash.splashFactory,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: ()=> Navigator.pop(context),
                          child: Text(CoreMessages.of(context).close, style: TextStyle(color: Color(0xFF1947FF)))
                      )
                  )
                  else if (actions.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScaler = MediaQuery.textScalerOf(context);
                        bool isHorizontalFit = true;
                        final dividerSpace = actions.length > 1 ? (actions.length - 1) * 16 : 0;
                        final availableWidthPerButton = (constraints.maxWidth - dividerSpace) / actions.length;

                        for (var action in actions) {
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: action.title, 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), // Đồng bộ Font Weight với App
                            ),
                            maxLines: 1,
                            textScaler: textScaler,
                            textDirection: TextDirection.ltr,
                          )..layout();

                          final requiredWidth = textPainter.width + 32; 

                          if (requiredWidth > availableWidthPerButton) {
                            isHorizontalFit = false;
                            break;
                          }
                        }

                        if (isHorizontalFit) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: IntrinsicHeight(
                              child: Row(
                                children: List.generate(actions.length * 2 - 1, (index) {
                                  if (index.isEven) {
                                    final item = actions[index ~/ 2];
                                    return Expanded(
                                      child: TextButton(
                                        onPressed: item.onTap,
                                        style: ButtonStyle(
                                          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                                          splashFactory: NoSplash.splashFactory,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          item.title,
                                          style: TextStyle(color: item.color),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }
                                  return VerticalDivider(
                                    indent: 5,
                                    endIndent: 10,
                                    color: Colors.grey.op2,
                                  );
                                }),
                              ),
                            ),
                          );
                        } else {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(actions.length * 2 - 1, (index) {
                              if (index.isEven) {
                                final item = actions[index ~/ 2];
                                return TextButton(
                                  onPressed: item.onTap,
                                  style: ButtonStyle(
                                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                                    splashFactory: NoSplash.splashFactory,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    item.title,
                                    style: TextStyle(color: item.color),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return Divider(
                                height: 1,
                                color: Colors.grey.op2,
                                indent: 10,
                                endIndent: 10,
                              );
                            }),
                          );
                        }
                      },
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonAction {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ButtonAction({
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF1947FF)
  });
}