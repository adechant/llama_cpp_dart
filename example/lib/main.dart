import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    String modelPath = '/Users/adechant/projects/wellspoken/assets/models/gemma-3-1b-it-Q8_0.gguf';
    File model = File(modelPath);
    if(model.existsSync()){
      print('Found model');
    } else {
      print ('Model not found. Exiting...');
      exit(1);
    }

    Llama(modelPath);

  } catch (e) {
    print(e);
  }
}
