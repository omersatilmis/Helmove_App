
import 'dart:io';

void main() {
  const filePath = 'c:\\Users\\omerf\\FlutterProjeleri\\helmove\\lib\\core\\di\\injection_container.dart';
  final file = File(filePath);
  if (!file.existsSync()) {
    stdout.writeln('File not found: $filePath');
    return;
  }
  
  var content = file.readAsStringSync();
  
  // Use a more robust way to remove the block
  // We'll search for the attendance feature comment and the following 3 if blocks
  final regex = RegExp(
    r'// Attendance Feature\s+if \(!sl\.isRegistered<AttendanceApi>\(\)\) \{(?:.|\n)*?if \(!sl\.isRegistered<AttendanceRepository>\(\)\) \{(?:.|\n)*?\}',
  );
  
  final match = regex.firstMatch(content);
  if (match == null) {
    stdout.writeln('Regex failed to find the Attendance block.');
    return;
  }
  
  final matchedText = match.group(0)!;
  stdout.writeln('Found block:\n$matchedText');
  
  // 1. Remove it from its current position (deferred feature set)
  content = content.replaceFirst(matchedText, '  // Attendance Feature moved to core for GroupRideBloc dependency');
  
  // 2. Insert it into core feature set (after PostsBloc registration)
  final postsBlocEnd = RegExp(r'if \(!sl\.isRegistered<PostsBloc>\(\)\) \{(?:.|\n)*?\}\s+\}');
  final coreMatch = postsBlocEnd.firstMatch(content);
  
  if (coreMatch == null) {
    stdout.writeln('Could not find PostsBloc ending to insert after.');
    return;
  }
  
  final insertPosition = coreMatch.end;
  final updatedAttendanceBlock = matchedText.replaceAll(
    '// Attendance Feature',
    '// Attendance Feature (Core dependency for GroupRideBloc)',
  );
  
  final newContent = '${content.substring(0, insertPosition)}\n\n  $updatedAttendanceBlock${content.substring(insertPosition)}';
  
  file.writeAsStringSync(newContent);
  stdout.writeln('Successfully moved Attendance registrations to CORE.');
}
