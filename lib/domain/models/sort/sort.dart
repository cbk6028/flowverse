enum SortOption {
  fileName('文件名'),
  fileSize('文件大小');
  // lastRead('最近阅读'),
  // openCount('打开次数');

  final String label;
  const SortOption(this.label);
}

enum SortDirection {
  ascending('升序'),
  descending('降序');

  final String label;
  const SortDirection(this.label);
}

class Sort {
  Sort({
    required this.option,
    required this.direction,
  });
  SortOption option;
  SortDirection direction;

  Map<String, int> _openCounts = {};
  Map<String, DateTime> _lastReadTimes = {};
}
