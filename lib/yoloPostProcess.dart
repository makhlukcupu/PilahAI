import 'dart:math';

class YoloPostProcessor {
  final double confThreshold;
  final double nmsThreshold;

  YoloPostProcessor({this.confThreshold = 0.6, this.nmsThreshold = 0.4});

  List<Map<String, dynamic>> processOutput(
      List<List<List<double>>> output,
      int numBoxes,
      int numClasses) {

    final outputData = output[0];

    // Split into boxes (coordinates) and class probabilities
    final boxes = outputData.sublist(0, 4); // center (x, y), width and height
    final classProbs = outputData.sublist(4); // Remaining rows are class probabilities

    final results = <Map<String, dynamic>>[];

    for (var boxIdx = 0; boxIdx < numBoxes; boxIdx++) {
      // Get the box coordinates [x1, y1, x2, y2]
      final box = [
        boxes[0][boxIdx] - boxes[2][boxIdx]/2, // x1
        boxes[1][boxIdx] - boxes[3][boxIdx]/2, // y1
        boxes[0][boxIdx] + boxes[2][boxIdx]/2, // x2
        boxes[1][boxIdx] + boxes[3][boxIdx]/2, // y2
      ];

      // Get all class probabilities for this box
      final probs = List<double>.generate(
          numClasses,
              (classIdx) => classProbs[classIdx][boxIdx]
      );

      // Find the class with highest probability
      var maxProb = 0.0;
      var classId = 0;
      for (var i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          classId = i;
        }
      }

      // Only keep if confidence exceeds threshold
      if (maxProb > confThreshold) {
        results.add({
          'box': box,
          'classIndex': classId,
          'confidence': maxProb,
        });
      }
    }

    return nonMaximumSuppression(results, nmsThreshold);

    //int stride = numClasses + 4; // YOLOv11 output format

    // for (int i = 0; i < numBoxes; i++) {
    //   double maxClassProb = 0;
    //   int classIndex = -1;
    //   for (int j = 0; j < numClasses; j++) {
    //     double classProb = rawOutput[i + (4 + j)*numBoxes];
    //     if (classProb > maxClassProb) {
    //       maxClassProb = classProb;
    //       classIndex = j;
    //     }
    //   }
    //
    //   if (maxClassProb > confThreshold){
    //
    //     double x = rawOutput[i];
    //     double y = rawOutput[i + numBoxes];
    //     double w = rawOutput[i+ 2*numBoxes];
    //     double h = rawOutput[i + 3*numBoxes];
    //
    //     double xMin = x - w / 2;
    //     double yMin = y - h / 2;
    //     double xMax = x + w /2;
    //     double yMax = y + h /2;
    //
    //
    //     detections.add({
    //       "box": [xMin, yMin, xMax, yMax],
    //       "confidence": maxClassProb,
    //       "classIndex": classIndex
    //     });
    //     //print("x= " +xMin.toString() + "// y= "+yMin.toString() +"// ini termasuk " + classIndex.toString() + "// confScore= "+maxClassProb.toString());
    //   }
    // }
    // //return detections;

    //return nonMaximumSuppression(detections, nmsThreshold);
  }

  List<Map<String, dynamic>> nonMaximumSuppression(List<Map<String, dynamic>> detections, double threshold) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b["confidence"].compareTo(a["confidence"]));
    List<bool> keep = List.filled(detections.length, true);

    for (int i = 0; i < detections.length; i++) {
      if (!keep[i]) continue;

      for (int j = i + 1; j < detections.length; j++) {
        if (!keep[j]) continue;

        if (iou(detections[i]["box"], detections[j]["box"]) > threshold) {
          keep[j] = false;
        }
      }
    }

    return [for (int i = 0; i < detections.length; i++) if (keep[i]) detections[i]];
  }

  double iou(List<double> boxA, List<double> boxB) {
    double x1 = max(boxA[0], boxB[0]);
    double y1 = max(boxA[1], boxB[1]);
    double x2 = min(boxA[2], boxB[2]);
    double y2 = min(boxA[3], boxB[3]);

    double intersection = max(0, x2 - x1) * max(0, y2 - y1);
    double areaA = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
    double areaB = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]);
    double unionArea = areaA + areaB - intersection;

    return intersection / unionArea;
  }
}
