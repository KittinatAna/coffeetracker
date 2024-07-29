import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _volumeInterpreter;
  late Interpreter _expenditureInterpreter;

  Future<void> loadModel() async {
    
    _volumeInterpreter = await Interpreter.fromAsset('assets/volume_forecast_model_6m.tflite');
    _expenditureInterpreter = await Interpreter.fromAsset('assets/expenditure_forecast_model_3m.tflite');
  }

  double predictVolume(double input) {
    try {
      var inputTensor = [[input]];
      var outputTensor = List<double>.filled(1*1, 0.0).reshape([1,1]);

      print('inputTensor: $inputTensor');
      print('outputTensor: $outputTensor');

      _volumeInterpreter.run(inputTensor, outputTensor);
      print("Completed prediction");
      
      print('outputTensor[0][0]: ${outputTensor[0][0]}');
      return outputTensor[0][0];
    } catch (e) {
      print("Error during prediction: $e");
      return 0.0;
    }
  }

  double predictExpenditure(List<double> input) {
    try {
      var inputTensor = List.generate(1, (_) => List.generate(3, (_) => List.filled(2, 0.0)));
      for (int i = 0; i < input.length; i++) {
        inputTensor[1][i ~/ 2][i % 2] = input[i];
      }
      var outputTensor = List.filled(1, 0.0);

      print('inputTensor: $inputTensor');

      _expenditureInterpreter.run(inputTensor, outputTensor);
      print("Completed prediction");
      
      print('outputTensor[0][0]: ${outputTensor[0]}');
      return outputTensor[0];
    } catch (e) {
      print("Error during prediction: $e");
      return 0.0;
    }
  }
}