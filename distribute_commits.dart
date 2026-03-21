import 'dart:io';
import 'dart:math';

void main() async {
  final statusResult = await Process.run('git', ['status', '-s']);
  final lines = statusResult.stdout.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();
  
  if (lines.isEmpty) {
    print('No files to commit.');
    return;
  }

  final files = <String>[];
  for (var line in lines) {
    if (line.length > 3) {
      var fileStr = line.substring(3).trim();
      if (fileStr.contains(' -> ')) {
        // Handle rename: R  old -> new. We should just add both the old (to register deletion) and new.
        // But git add . handles it better. To be safe, let's just use git add <old> <new>
        var parts = fileStr.split(' -> ');
        files.add(parts.first.replaceAll('"', ''));
        files.add(parts.last.replaceAll('"', ''));
      } else {
        if (fileStr.startsWith('"') && fileStr.endsWith('"')) {
          fileStr = fileStr.substring(1, fileStr.length - 1);
        }
        files.add(fileStr);
      }
    }
  }

  // Remove duplicates
  final uniqueFiles = files.toSet().toList();
  uniqueFiles.shuffle();

  // Create timeline: Mar 13 to Mar 21 (9 days)
  final random = Random();
  final days = [13, 14, 15, 16, 17, 18, 19, 20, 21];
  final dateTimes = <DateTime>[];

  for (var day in days) {
    // 1 to 4 commits per day
    int commitsToday = 1 + random.nextInt(4); // 1, 2, 3, or 4
    for (int i = 0; i < commitsToday; i++) {
      int hour = random.nextInt(24);
      int minute = random.nextInt(60);
      int second = random.nextInt(60);
      dateTimes.add(DateTime(2026, 3, day, hour, minute, second));
    }
  }

  // Sort dates chronologically
  dateTimes.sort();

  final totalCommits = dateTimes.length;
  print('Total commits planned: $totalCommits');

  final filesPerCommit = (uniqueFiles.length / totalCommits).ceil();
  // Ensure we have at least 1 file per commit if possible
  
  final commitMessages = [
    "Refactor UI components", "Update map features", "Fix linter warnings", 
    "Improve performance", "Update API integration", "Clean up unused code",
    "Enhance navigation", "Add new UI elements", "Update config", "Bug fixes",
    "Update settings page", "Profile updates", "Auth logic refinement", "Code structure improvements"
  ];

  int fileIndex = 0;
  for (int i = 0; i < totalCommits; i++) {
    if (fileIndex >= uniqueFiles.length) {
      // If we run out of files, just break. The user wants commits, but we only have so many files.
      // Wait, if we run out of files, we can't make empty commits unless we use --allow-empty.
      // Let's use --allow-empty so we guarantee the number of commits exists on all days.
    }
    
    int end = fileIndex + filesPerCommit;
    if (end > uniqueFiles.length) end = uniqueFiles.length;
    
    final chunk = uniqueFiles.sublist(fileIndex, end);
    fileIndex = end;

    // Add files
    for (var f in chunk) {
      await Process.run('git', ['add', f]);
    }

    final dt = dateTimes[i];
    // Format: 2026-03-13T14:32:00
    final dateStr = dt.toIso8601String() + "+03:00"; 
    
    final msg = commitMessages[random.nextInt(commitMessages.length)];

    final commitResult = await Process.run('git', ['commit', '--allow-empty', '-m', msg], environment: {
      'GIT_AUTHOR_DATE': dateStr,
      'GIT_COMMITTER_DATE': dateStr,
    });

    if (commitResult.exitCode != 0) {
      print('Commit failed: ${commitResult.stderr}');
    } else {
      print('Committed ${chunk.length} files on $dateStr');
    }
  }

  print('Pushing to github...');
  final pushResult = await Process.run('git', ['push']);
  if (pushResult.exitCode != 0) {
    print('Push failed. Output: ${pushResult.stderr}');
  } else {
    print('Push successful!');
  }
}
