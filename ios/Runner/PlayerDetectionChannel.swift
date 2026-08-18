import Flutter
import UIKit
import Vision

enum PlayerDetectionChannel {
  static let name = "io.grinta.app/player_detection"

  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "detectPeople" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let typed = args["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "bad_args", message: "bytes required", details: nil))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        let boxes = detectPeople(in: typed.data)
        DispatchQueue.main.async {
          result(boxes)
        }
      }
    }
  }

  private static func detectPeople(in data: Data) -> [[String: Double]] {
    guard let image = UIImage(data: data), let cgImage = image.cgImage else {
      return []
    }

    let request = VNDetectHumanRectanglesRequest()
    if #available(iOS 15.0, *) {
      request.upperBodyOnly = false
    }
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return []
    }

    let observations = request.results ?? []
    return observations.compactMap { observation in
      let box = observation.boundingBox
      let height = Double(box.height)
      let width = Double(box.width)
      if width <= 0 || height <= 0 { return nil }
      return [
        "left": Double(box.origin.x),
        "top": 1.0 - Double(box.origin.y) - height,
        "width": width,
        "height": height,
        "score": Double(observation.confidence),
      ]
    }
  }
}
