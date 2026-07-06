// app_constants.dart
//
// Application-wide tunables. Centralising them here makes it easy to tweak
// the app's behaviour from a single place, and keeps the algorithms self
// documenting.

/// Default sensor sampling period in microseconds. sensors_plus accepts a
/// Duration; smaller = higher rate. ~5 ms = 200 Hz, which is well above the
/// screen refresh rate of most phones and gives the integration step a
/// realistic interval to work with.
const Duration kDefaultSamplingPeriod = Duration(microseconds: 5 * 1000);

/// How many samples of history each live graph keeps on screen. At 200 Hz
/// this is ~5 seconds of history. The graph widget renders all of them
/// every frame, so going much higher than this starts to cost CPU.
const int kGraphHistoryLength = 1024;

/// How long a row of CSV stays in the in-memory buffer before being flushed
/// to disk. We trade a small amount of data loss on crash for not hammering
/// the filesystem at 200 Hz.
const Duration kLogFlushInterval = Duration(milliseconds: 500);

/// Maximum rows buffered in memory before forcing a flush. Safety valve.
const int kLogBufferMaxRows = 4096;

/// The size of the moving-average and median filter windows, in samples.
/// 5 is a good compromise: enough to reject a single outlier spike without
/// introducing visible lag at 200 Hz (~25 ms of smoothing).
const int kDefaultFilterWindow = 5;

/// Default complementary filter coefficient `alpha`. `alpha = 0.98` means
/// we trust the gyroscope 98% of the time and the absolute reference 2%.
/// Higher = less drift, more susceptible to magnetic noise and jolts.
const double kDefaultComplementaryAlpha = 0.98;

/// The "stillness" threshold in rad/s used to decide when to update the
/// gyro bias estimate. If the magnitude of the gyroscope is below this
/// value we assume the device is at rest and average the reading into
/// the bias.
const double kStillnessThresholdRadPerSec = 0.01; // ~0.57 deg/s

/// Number of "still" samples required before the bias estimate is updated.
/// 200 samples at 5 ms = 1 second of stillness to start correcting drift.
const int kStillnessSampleCount = 200;
