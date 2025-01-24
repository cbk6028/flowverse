import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../view_models/reader_vm.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                PhosphorIconsLight.house,
                color: Colors.black87,
                size: 20,
              ),
            ),
            onPressed: () async {
              await appState.markerVm.saveHighlights(appState.currentPdfPath);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  PhosphorIconsLight.hand,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: () {
                  appState.topbarVm.resetToolStates();
                  // appState.topbarVm.isHandSelected = true;
                  // appState.markerVm.applyMark();
                },
              ),
              CupertinoButton(
                key: appState.topbarVm.brushButtonKey,
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: appState.markerVm.highlightColor.withOpacity(0.1),
                    // ? Colors.blue.withOpacity(0.1)
                    // : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIconsLight.highlighter,
                    color: appState.markerVm.highlightColor,
                    size: 20,
                  ),
                ),
                onPressed: () async {
                  if (false) {
                    appState.topbarVm.resetToolStates();
                    appState.topbarVm.isBrushSelected = true;
                    appState.markerVm.currentMarkerType = MarkerType.highlight;
                  } else {
                    appState.topbarVm.resetToolStates();
                    appState.topbarVm.isBrushSelected = true;

                    final RenderBox? button = appState
                        .topbarVm.brushButtonKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    final RenderBox? overlay = Overlay.of(context)
                        .context
                        .findRenderObject() as RenderBox?;

                    if (button != null && overlay != null) {
                      final buttonSize = button.size;
                      final buttonPosition = button.localToGlobal(Offset.zero);

                      await showMenu(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        position: RelativeRect.fromLTRB(
                            buttonPosition.dx,
                            buttonPosition.dy + buttonSize.height,
                            buttonPosition.dx + 200,
                            buttonPosition.dy + buttonSize.height + 200),
                        items: [
                          PopupMenuItem(
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: 200,
                              padding: EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.blue),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Container(
                                            height: 2,
                                            width: 60,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 80,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.blue),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Container(
                                            height: 4,
                                            width: 60,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      Colors.yellow,
                                      Colors.orange,
                                      Colors.red,
                                      Colors.pink,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.brown,
                                      Colors.grey,
                                      Colors.black,
                                    ]
                                        .map((color) => GestureDetector(
                                              onTap: () {
                                                appState.markerVm
                                                        .highlightColor =
                                                    color as MaterialColor;
                                                setState(() {});
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                },
              ),
              // underline
              CupertinoButton(
                key: appState.topbarVm.underlineButtonKey,
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: appState.markerVm.underlineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIconsLight.textUnderline,
                    color: appState.markerVm.underlineColor,
                    size: 20,
                  ),
                ),
                onPressed: () async {
                  if (false) {
                    appState.topbarVm.resetToolStates();
                    appState.topbarVm.isUnderlineSelected = true;
                    appState.markerVm.currentMarkerType = MarkerType.underline;
                  } else {
                    appState.topbarVm.resetToolStates();
                    appState.topbarVm.isUnderlineSelected = true;

                    final RenderBox? button = appState
                        .topbarVm.underlineButtonKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    final RenderBox? overlay = Overlay.of(context)
                        .context
                        .findRenderObject() as RenderBox?;

                    if (button != null && overlay != null) {
                      final buttonSize = button.size;
                      final buttonPosition = button.localToGlobal(Offset.zero);

                      await showMenu(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        position: RelativeRect.fromLTRB(
                            buttonPosition.dx,
                            buttonPosition.dy + buttonSize.height,
                            buttonPosition.dx + 200,
                            buttonPosition.dy + buttonSize.height + 200),
                        items: [
                          PopupMenuItem(
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: 200,
                              padding: EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.blue),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Container(
                                            height: 1,
                                            width: 60,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 80,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.blue),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Container(
                                            height: 2,
                                            width: 60,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      Colors.yellow,
                                      Colors.orange,
                                      Colors.red,
                                      Colors.pink,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.brown,
                                      Colors.grey,
                                      Colors.black,
                                    ]
                                        .map((color) => GestureDetector(
                                              onTap: () {
                                                appState.markerVm
                                                        .underlineColor =
                                                    color as MaterialColor;
                                                setState(() {});
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                },
              ),
              //
              CupertinoButton(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color:
                        appState.markerVm.strikethroughColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIconsLight.textStrikethrough,
                    color: appState.markerVm.strikethroughColor,
                    size: 20,
                  ),
                ),
                onPressed: () async {
                  final RenderBox? button = appState
                      .topbarVm.underlineButtonKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  final RenderBox? overlay = Overlay.of(context)
                      .context
                      .findRenderObject() as RenderBox?;

                  if (button != null && overlay != null) {
                    final buttonSize = button.size;
                    final buttonPosition = button.localToGlobal(Offset.zero);

                    await showMenu(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: Colors.white,
                      position: RelativeRect.fromLTRB(
                          buttonPosition.dx,
                          buttonPosition.dy + buttonSize.height,
                          buttonPosition.dx + 200,
                          buttonPosition.dy + buttonSize.height + 200),
                      items: [
                        PopupMenuItem(
                          padding: EdgeInsets.zero,
                          child: Container(
                            width: 200,
                            padding: EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Container(
                                          height: 1,
                                          width: 60,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 80,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Container(
                                          height: 2,
                                          width: 60,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.red,
                                    Colors.pink,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.purple,
                                    Colors.brown,
                                    Colors.grey,
                                    Colors.black,
                                  ]
                                      .map((color) => GestureDetector(
                                            onTap: () {
                                              appState.markerVm
                                                      .strikethroughColor =
                                                  color as MaterialColor;
                                              setState(() {});
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(12.0),
                child: const Icon(
                  PhosphorIconsLight.arrowUUpLeft,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                onPressed: () {
                  appState.markerVm.undo();
                },
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(12.0),
                child: const Icon(
                  PhosphorIconsLight.arrowUUpRight,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                onPressed: () {
                  appState.markerVm.redo();
                },
              ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => appState.toggleDarkMode(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      appState.darkMode
                          ? PhosphorIconsLight.moon
                          : PhosphorIconsLight.sun,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
