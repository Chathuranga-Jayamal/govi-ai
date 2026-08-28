import 'package:image_picker/image_picker.dart';

import 'prediction_result.dart';

/// Bundles the captured image and its prediction for the `/capture/result`
/// route's single `extra` slot.
class CaptureResultArgs {
  const CaptureResultArgs({required this.image, required this.result});

  final XFile image;
  final PredictionResult result;
}
