import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    String modelPath =
        '/Users/adechant/projects/wellspoken/assets/models/gemma-3-1b-it-Q8_0.gguf';
    if (Platform.isMacOS) {
    } else if (Platform.isWindows) {
      modelPath = 'C:/Users/antho/Documents/Jonathan/gemma-3-12b-it-Q8_0.gguf';
    } else if (Platform.isLinux) {
      print('Running on Linux');
    } else {
      print('Unknown platform');
    }

    File model = File(modelPath);
    if (model.existsSync()) {
      print('Found model');
    } else {
      print('Model not found. Exiting...');
      exit(1);
    }

    /*File dll = File('llama.dll');
    if (dll.existsSync()) {
      print('Found dll');
    } else {
      print('DLL not found. Exiting...');
      exit(1);
    }*/

    final Llama llama = Llama(modelPath);
    final Stream<String> output =
        llama.generate('What is the capital of France?');
    await for (String line in output) {
      print(line);
    }
  } catch (e) {
    print(e);
  }
}
