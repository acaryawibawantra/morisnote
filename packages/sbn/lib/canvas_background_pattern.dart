enum CanvasBackgroundPattern(
  /// The pattern name used for serialization.
  /// Do not display this to the user: instead use [localizedName].
  final String name, {

  /// Whether this pattern has elements along the page edges that may need to be
  /// clipped.
  final bool requiresClipping = false,
}) {
  /// No background pattern
  none(''),

  /// College ruled paper (ltr): horizontal lines with one
  /// vertical line along the left margin
  collegeLtr('college'),

  /// College ruled paper (rtl): horizontal lines with one
  /// vertical line along the right margin
  collegeRtl('college-rtl'),

  /// Horizontal lines. This is the same as college ruled paper
  /// but without the vertical line
  lined('lined'),

  /// A grid of squares
  grid('grid', requiresClipping: true),

  /// A grid of dots. This is the same as "grid" except it has dots on the
  /// corners instead of the whole square border.
  dots('dots', requiresClipping: true),

  /// Music staffs
  staffs('staffs'),

  /// Music tablature
  ///
  /// Like staffs but with 6 lines instead of 5 (and 5 spaces instead of 4).
  tablature('tablature'),

  /// Cornell notes
  cornell('cornell'),

  /// Graph paper: a fine grid with a bolder line every fifth square
  graph('graph', requiresClipping: true),

  /// Isometric (triangular) grid, useful for 3D sketches
  isometric('isometric', requiresClipping: true),

  /// Hexagonal honeycomb grid
  hex('hex', requiresClipping: true),

  /// Weekly planner: seven day columns under a header row
  weeklyPlanner('weekly-plan'),

  /// Daily planner: hourly rows with a time column on the left
  dailyPlanner('daily-plan'),

  /// Checklist: checkbox and a writing line per row
  checklist('checklist'),

  /// Storyboard: six frames (2 columns x 3 rows)
  storyboard('storyboard'),

  /// Calligraphy guides: four lines with an x-height band
  calligraphy('calligraphy'),

  /// Top half blank for sketches, bottom half ruled
  halfLined('half-lined');

  static CanvasBackgroundPattern fromName(String? name) {
    return values.firstWhere(
      (pattern) => pattern.name == name,
      orElse: () => CanvasBackgroundPattern.none,
    );
  }
}
