part of 'dashboard_screen.dart';

class Cover extends StatefulWidget {
  final String filePath;

  const Cover({Key? key, required this.filePath}) : super(key: key);

  @override
  State<Cover> createState() => _CoverState();
}

class _CoverState extends State<Cover> {
  PdfDocument? _document;
  PdfPage? _page;
  bool _isLoading = true;
  String? _error;
  ui.Image? _thumbnail;
  String? _fileHash;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      // 计算文件哈希
      _fileHash = await FileUtils.calculateFileHash(widget.filePath);

      // 检查缓存
      final cachedImage =
          await DefaultCacheManager().getFileFromCache(_fileHash!);

      if (cachedImage != null && cachedImage.file.existsSync()) {
        final bytes = await cachedImage.file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frameInfo = await codec.getNextFrame();
        _thumbnail = frameInfo.image;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _document = await PdfDocument.openFile(widget.filePath);
      _page = await _document!.pages[0];

      // 使用固定的缩略图尺寸
      final targetWidth = 200.0;
      final targetHeight = (targetWidth / _page!.width * _page!.height);

      final pdfImage = await _page!.render(
        fullWidth: targetWidth,
        fullHeight: targetHeight,
      );

      _thumbnail = await pdfImage?.createImage();

      // 缓存缩略图
      if (_thumbnail != null) {
        final byteData =
            await _thumbnail!.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          await DefaultCacheManager().putFile(
            _fileHash!,
            byteData.buffer.asUint8List(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _resetState() {
    // 清理旧资源
    _thumbnail?.dispose();
    _thumbnail = null;

    _document?.dispose();
    _document = null;

    _page = null;
    _fileHash = null;
    _error = null;
    _isLoading = true;
  }

  @override
  void didUpdateWidget(Cover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 filePath 发生变化，重新加载缩略图
    if (oldWidget.filePath != widget.filePath) {
      _resetState();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _thumbnail?.dispose();
    _document?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_error != null || _thumbnail == null) {
      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Center(
          child: Icon(PhosphorIconsRegular.fileText,
              size: 48, color: CupertinoColors.systemGrey),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: _thumbnail != null
            ? RawImage(
                image: _thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : const Center(
                child: Icon(PhosphorIconsRegular.fileText,
                    size: 48, color: CupertinoColors.systemGrey),
              ),
      ),
    );
  }
}

// 新增的 BookCard 组件
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMoreOptions;
  final bool isFavorite;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.onFavorite,
    this.onMoreOptions,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _controller.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _controller.reverse();
        });
      },
      child: GestureDetector(
        onTap: () {
          // 如果提供了 onTap 回调，则使用它
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            // 默认行为：新建标签页
            AppTabController().addTab(TabItem(
              id: widget.book.path,
              title: widget.book.name,
              icon: PhosphorIconsRegular.filePdf,
              content: ReaderScreen(
                filePath: widget.book.path,
                book: widget.book,
              ),
            ));
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: _isHovering ? 8 : 4,
                  offset: Offset(0, _isHovering ? 4 : 2),
                ),
              ],
              border: Border.all(
                color: _isHovering
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 缩略图区域
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 缩略图
                        Cover(filePath: widget.book.path),

                        // 顶部渐变阴影
                        // Positioned(
                        //   top: 0,
                        //   left: 0,
                        //   right: 0,
                        //   height: 40,
                        //   child: Container(
                        //     decoration: BoxDecoration(
                        //       gradient: LinearGradient(
                        //         begin: Alignment.topCenter,
                        //         end: Alignment.bottomCenter,
                        //         colors: [
                        //           Colors.black.withOpacity(0.3),
                        //           Colors.transparent,
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        // 操作按钮
                      //   if (widget.onMoreOptions != null)
                      //     Positioned(
                      //       top: 8,
                      //       right: 8,
                      //       child: ClipRRect(
                      //         borderRadius: BorderRadius.circular(8),
                      //         child: BackdropFilter(
                      //           filter: ui.ImageFilter.blur(
                      //             sigmaX: 2.0,
                      //             sigmaY: 2.0,
                      //           ),
                      //           child: Container(
                      //             height: 20,
                      //             // padding: const EdgeInsets.all(4),
                      //             decoration: BoxDecoration(
                      //               color: Colors.black.withOpacity(0.2),
                      //               borderRadius: BorderRadius.circular(8),
                      //             ),
                      //             child: Row(
                      //               children: [
                      //                 // 更多选项按钮
                      //                 IconButton(
                      //                   // padding: EdgeInsets.zero,
                      //                   onPressed: widget.onMoreOptions,
                      //                   icon: const Icon(
                      //                     CupertinoIcons.ellipsis,
                      //                     color: Colors.white,
                      //                     // size: 16/,
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      ],
                    ),
                  ),
                ),

                // 文件信息区域
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 文件名
                      Text(
                        widget.book.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 文件信息
                      Row(
                        children: [
                          // 日期
                          Icon(
                            CupertinoIcons.calendar,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(
                                widget.book.lastReadTime ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          // 文件大小
                          Icon(
                            CupertinoIcons.doc,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.book.fileSize.isNotEmpty
                                ? _formatFileSize(
                                    int.tryParse(widget.book.fileSize) ?? 0)
                                : "1 B",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
