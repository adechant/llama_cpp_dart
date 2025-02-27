import "package:llama_cpp_dart/src/chat_template.dart";
import 'package:typed_isolate/typed_isolate.dart';

import "llama.dart";
import "isolate_types.dart";

class LlamaChild extends IsolateChild<LlamaResponse, LlamaCommand> {
  LlamaChild() : super(id: 1);

  Llama? llama;
  LlmChatTemplate _template = LlmChatTemplate.chatml;

  @override
  void onData(LlamaCommand data) {
    try {
      switch (data) {
        case LlamaStop() || LlamaClear():
          llama?.stop();
          llama?.clear();
          break;
        case LlamaLoad(
            :final path,
            :final modelParams,
            :final contextParams,
            :final samplingParams
          ):
          llama = Llama(path, modelParams, contextParams, samplingParams);
          _template = llmChatDetectTemplate(llama?.fetchChatTemplate() ?? '');
          break;
        case LlamaChatMessage():
          _prompt(data);
          break;
        case LlamaInit(:final libraryPath):
          Llama.libraryPath = libraryPath;
          break;
        default:
          break;
      }
    } catch (e) {
      sendToParent(LlamaChatError(error: e.toString()));
    }
  }

  void _prompt(LlamaChatMessage data) {
    String formattedPrompt =
        llmChatApplyTemplate(_template, data, data.addAssistant);
    if (formattedPrompt.isEmpty) {
      return;
    }

    Stream<String>? response = llama?.generate(formattedPrompt);
    response?.listen((text) {
      final response = LlamaChatMessage('assistant', text);
      sendToParent(response); // Send response to parent
    }, onDone: () {
      sendToParent(LlamaChatDone());
    }, onError: (e) {
      sendToParent(LlamaChatError(error: 'Error generating text $e'));
    });
  }
}
