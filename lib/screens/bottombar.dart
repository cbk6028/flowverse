import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flowverse/view_models/reader_vm.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row(
          //   children: [
          //     Text(
          //       '第 ${appState.currentPage + 1} 页',
          //       style: const TextStyle(
          //         fontSize: 14,
          //         color: Colors.black87,
          //       ),
          //     ),
          //     const Text(
          //       ' / ',
          //       style: TextStyle(
          //         fontSize: 14,
          //         color: Colors.black54,
          //       ),
          //     ),
          //     Text(
          //       '${appState.pdfViewerController.pageCount} 页',
          //       style: const TextStyle(
          //         fontSize: 14,
          //         color: Colors.black54,
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // CupertinoButton(
                    //   padding: EdgeInsets.zero,
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8.0),
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: const Icon(
                    //       PhosphorIconsLight.minus,
                    //       color: Colors.black87,
                    //       size: 20,
                    //     ),
                    //   ),
                    //   onPressed: () {
                    //     appState.zoomDown();
                    //   },
                    // ),
                    // const SizedBox(width: 8),
                    // Text(
                    //   '${(appState.pdfViewerController.currentZoom * 100).toInt()}%',
                    //   style: const TextStyle(
                    //     fontSize: 14,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    // const SizedBox(width: 8),
                    // CupertinoButton(
                    //   padding: EdgeInsets.zero,
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8.0),
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: const Icon(
                    //       PhosphorIconsLight.plus,
                    //       color: Colors.black87,
                    //       size: 20,
                    //     ),
                    //   ),
                    //   onPressed: () {
                    //     appState.zoomUp();
                    //   },
                    // ),
                    // const SizedBox(width: 16),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          appState.isDoublePageMode
                              ? PhosphorIconsLight.notebook
                              : PhosphorIconsLight.bookOpenText,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        appState.isDoublePageMode = !appState.isDoublePageMode;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
