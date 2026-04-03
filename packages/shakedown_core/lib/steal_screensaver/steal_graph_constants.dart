part of 'steal_graph.dart';

const int _algoCount = 6;

/// Number of FFT bands rendered.
const int _bandCount = 8;

/// Number of bars in corner graph (8 FFT bands + 1 beat indicator).
const int _cornerBarCount = 9;

// Corner graph layout.
const double _barWidth = 8.0;
const double _barGap = 4.0;
const double _maxBarHeight = 80.0;
const double _bottomPadding = 64.0;
const double _leftPadding = 48.0;
const double _cornerRadius = 3.0;

const List<String> _cornerLabels = [
  'SUB',
  'BASS',
  'LMID',
  'MID',
  'UMID',
  'PRES',
  'BRIL',
  'AIR',
  'BEAT',
];

// Circular graph layout.
const double _circBarWidth = 6.0;
const double _circMaxBarHeight = 40.0;

// EKG layout.
const int _ekgSampleCount = 150;
const double _ekgMaxHeight = 45.0;
const double _ekgRiseSmoothing = 18.0;
const double _ekgFallSmoothing = 8.0;
const double _ekgSampleRate = 60.0;

// Smoothing and visual timing.
const double _riseSmoothing = 15.0;
const double _fallSmoothing = 5.0;
const double _peakHoldDecayPerSec = 22.0;
const double _beatFlashDecayPerSec = 3.5;
const double _beatBarFallSmoothing = 7.0;

const List<String> _algoLabels = [
  'BASS\n0-250',
  'MID\n250-4k',
  'BROAD\nB+M',
  'ALL\nBANDS',
  'EMA\nMID',
  'TREB\n4k+',
];

// VU meter constants.
const double _vuRiseSmoothing = 12.0;
const double _vuFallSmoothing = 2.2;
const double _vuPeakDecayPerSec = 0.5;
const double _vuWidth = 155.0;
const double _vuHeight = 110.0;
const double _vuNeedleLength = 74.0;
const double _vuSweepHalf = 1.1;

// LED strip constants.
const double _ledStripWidth = 28.0;
const int _ledSegmentCount = 16;
const double _ledLabelReserve = 18.0;
const double _ledColGap = 2.0;
const double _ledSegGap = 1.5;
const double _ledHPad = 3.0;

const List<Color> _bandColors = [
  Color(0xFF34E7FF),
  Color(0xFF33D1FF),
  Color(0xFF4AF3C6),
  Color(0xFF8BFF91),
  Color(0xFFFFE66D),
  Color(0xFFFFB84D),
  Color(0xFFFF7A66),
  Color(0xFFFF58A8),
  Color(0xFFFFFFFF),
];
