import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../view_models/reader_vm.dart';




// class TopBar extends StatelessWidget {
//   const TopBar({super.key});

//   @override
//   Widget build(BuildContext context) {
    
//       // var appState = context.watch<ReaderViewModel>();

//       return  ChangeNotifierProvider(
//         create: (_) => TopbarViewModel(),
//         child: TopBarInner(),
//       );
//   }
// }

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

// class _TopbarState extends State<Topbar> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

class _TopBarState extends State<TopBar> {
  // const _TopbarState({super.key});

  @override
  Widget build(BuildContext context) {
      // var topbar_vm = context.watch<TopbarViewModel>();
      var appState = context.watch<ReaderViewModel>();

      return  Container(
        color: const Color(0xfff7f7f7),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.systemBlue,
              ),
              onPressed: () async {
                // 保存高亮
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
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.back_hand_outlined,
                    color: appState.topbarVm.isHandSelected ? CupertinoColors.systemBlue : CupertinoColors.black,
                  ),
                  onPressed: () {
                    appState.topbarVm.resetToolStates();
                    appState.topbarVm.isHandSelected = true;
                  },
                ),
                CupertinoButton(
                  key: appState.topbarVm.brushButtonKey,
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.brush_outlined,
                    color: appState.topbarVm.isBrushSelected 
                        ? appState.markerVm.highlightColor 
                        : CupertinoColors.black,
                  ),
                  onPressed: () async {
                    if (!appState.topbarVm.isBrushSelected) {
                      appState.topbarVm.resetToolStates();
                      appState.topbarVm.isBrushSelected = true;
                      // appState.markerVm.isHighlightMode = true;
                      appState.markerVm.currentMarkerType = MarkerType.highlight;
                    } else {
                      // 显示颜色选择菜单
                      final RenderBox? button = appState.topbarVm.brushButtonKey.currentContext?.findRenderObject() as RenderBox?;
                      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
      
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
                            buttonPosition.dy + buttonSize.height + 200
                          ),
                          items: [
                            PopupMenuItem(
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: 200,
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 笔画样式选择
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
                                    // 颜色选择
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
                                      ].map((color) => GestureDetector(
                                        onTap: () {
                                          appState.markerVm.highlightColor = color as MaterialColor;
                                          setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )).toList(),
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
                CupertinoButton(
                  key: appState.topbarVm.underlineButtonKey,
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.format_underline_outlined,
                    color: appState.topbarVm.isUnderlineSelected 
                        ? appState.markerVm.underlineColor 
                        : CupertinoColors.black,
                  ),
                  onPressed: () async {
                    if (!appState.topbarVm.isUnderlineSelected) {
                      appState.topbarVm.resetToolStates();
                      // appState.updateUnderlineState(true);
                      appState.topbarVm.isUnderlineSelected = true;
                      appState.markerVm.currentMarkerType = MarkerType.underline;
                    } else {
                      final RenderBox? button = appState.topbarVm.underlineButtonKey.currentContext?.findRenderObject() as RenderBox?;
                      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
      
                      if (button != null && overlay != null) {
                        final buttonSize = button.size;
                        final buttonPosition =
                            button.localToGlobal(Offset.zero);
      
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
                                    // 下划线样式选择
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blue),
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
                                            border: Border.all(
                                                color: Colors.blue),
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
                                    // 颜色选择
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
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: const Icon(
                    Icons.undo,
                    color: CupertinoColors.systemBlue,
                  ),
                  onPressed: () {
                    appState.markerVm.undo();
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: const Icon(
                    Icons.redo,
                    color: CupertinoColors.systemBlue,
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
              child: Icon(appState.darkMode
                  ? CupertinoIcons.moon
                  : CupertinoIcons.sun_max),
            ),
          ],
        ),
      );
    }
  }