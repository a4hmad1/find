/// Barrel for the shared widget library.
///
/// This file used to hold all 1,134 lines of it. The widgets now live in
/// focused files grouped by role; importing this one keeps every existing call
/// site working and gives new code a single obvious import.
library;

export 'app_scaffold.dart';
export 'buttons.dart';
export 'feedback.dart';
export 'inputs.dart';
export 'post_card.dart';
export 'tiles.dart';
