import 'package:core_flutter/common/color_opacity.dart';
import 'package:core_flutter/localization/core_messages.dart';
import 'package:core_flutter/overlay_ui/overlay_dialog.dart';
import 'package:flutter/material.dart';

class OverlayBottom extends StatelessWidget {
  final String title;
  final Widget body;
  final List<ButtonAction> actions;
  const OverlayBottom({
    super.key,
    required this.title,
    required this.body,
    required this.actions
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light 
              ? Colors.white 
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(30),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10)
            .add(const EdgeInsetsGeometry.only(bottom: 20)),
        padding: const EdgeInsets.symmetric(horizontal: 20)
            .add(const EdgeInsetsGeometry.symmetric(vertical: 15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(title.isNotEmpty) Expanded(
              child: Text(title, style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.black87 
                    : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,),
            ),
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: body,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(actions.isEmpty) Center(
                      child: TextButton(
                          style: ButtonStyle(
                            overlayColor: WidgetStatePropertyAll(Colors.transparent),
                            splashFactory: NoSplash.splashFactory,
                            minimumSize: WidgetStatePropertyAll(Size(double.infinity, 0)),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                                          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 0)),
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
                                    minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 0)),
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
              ),
            )
          ],
        ),
      ),
    );

  }
}
