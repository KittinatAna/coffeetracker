import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _volumeInterpreter;
  late Interpreter _expenditureInterpreter;

  Future<void> loadModel() async {
    _volumeInterpreter = await Interpreter.fromAsset('assets/volume_forecast_model_simple.tflite');
    _expenditureInterpreter = await Interpreter.fromAsset('assets/volume_forecast_model_simple.tflite');
  }

  double predictVolume(double input) {
    try {
      var inputTensor = [[input]];
      var outputTensor = List<double>.filled(1*1, 0.0).reshape([1,1]);

      print('inputTensor: $inputTensor');

      _volumeInterpreter.run(inputTensor, outputTensor);
      print("Completed prediction");
      
      print('outputTensor[0][0]: ${outputTensor[0][0]}');
      return outputTensor[0][0];
    } catch (e) {
      print("Error during prediction: $e");
      return 0.0;
    }
  }

  double predictExpenditure(double input) {
    try {
      var inputTensor = [[input]];
      var outputTensor = List<double>.filled(1*1, 0.0).reshape([1,1]);

      print('inputTensor: $inputTensor');

      _expenditureInterpreter.run(inputTensor, outputTensor);
      print("Completed prediction");
      
      print('outputTensor[0][0]: ${outputTensor[0][0]}');
      return outputTensor[0][0];
    } catch (e) {
      print("Error during prediction: $e");
      return 0.0;
    }
  }
}