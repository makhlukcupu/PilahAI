import 'dart:math';

class YoloPostProcessor {
  final double confThreshold;
  final double nmsThreshold;

  YoloPostProcessor({this.confThreshold = 0.6, this.nmsThreshold = 0.4});

  List<Map<String, dynamic>> processOutput(List<double> rawOutput, int numBoxes, int numClasses) {
    //print("waduuu " + rawOutput.length.toString());
    List<Map<String, dynamic>> detections = [];

    //int stride = numClasses + 4; // YOLOv11 output format

    for (int i = 0; i < numBoxes; i++) {
      double maxClassProb = 0;
      int classIndex = -1;
      for (int j = 0; j < numClasses; j++) {
        double classProb = rawOutput[i + (4 + j)*numBoxes];
        if (classProb > maxClassProb) {
          maxClassProb = classProb;
          classIndex = j;
        }
      }

      if (maxClassProb > confThreshold){
        // print(classIndex);
        // print(maxClassProb);

        double x = rawOutput[i];
        double y = rawOutput[i + numBoxes];
        double w = rawOutput[i+ 2*numBoxes];
        double h = rawOutput[i + 3*numBoxes];

        double xMin = x - w / 2;
        double yMin = y - h / 2;
        double xMax = x + w /2;
        double yMax = y + h /2;

        // // double maxClassProb = 0;
        // // int classIndex = -1;
        // // for (int j = 0; j < numClasses; j++) {
        // //   double classProb = rawOutput[offset + 4 + j];
        // //   if (classProb > maxClassProb) {
        // //     maxClassProb = classProb;
        // //     classIndex = j;
        // //   }
        // // }
        //
        // double finalScore = confidence * maxClassProb;


        detections.add({
          "box": [xMin, yMin, xMax, yMax],
          "confidence": maxClassProb,
          "classIndex": classIndex
        });
        //print("x= " +xMin.toString() + "// y= "+yMin.toString() +"// ini termasuk " + classIndex.toString() + "// confScore= "+maxClassProb.toString());
      }



    }
    //return detections;

    return nonMaximumSuppression(detections, nmsThreshold);
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
