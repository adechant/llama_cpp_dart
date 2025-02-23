import "package:llama_cpp_dart/src/chat_template.dart";
import 'package:typed_isolate/typed_isolate.dart';

import "llama.dart";
import "isolate_types.dart";

class LlamaChild extends IsolateChild<LlamaResponse, LlamaCommand> {
  LlamaChild() : super(id: 1);

  bool shouldStop = false;
  Llama? llama;
  LlmChatTemplate _template = LlmChatTemplate.chatml;
  final List<LlamaChatMessage> _messages = [];

  @override
  void onData(LlamaCommand data) {
    try {
      switch (data) {
        case LlamaStop() || LlamaClear():
          shouldStop = true;
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
          _messages.add(data);
          _sendPrompt(data);
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

  void _sendPrompt(LlamaChatMessage data) {
    String formattedPrompt =
        llmChatApplyTemplate(_template, data, data.addAssistant);
    if (formattedPrompt.isEmpty) {
      return;
    }
    _messages.add(data);
    llama?.setPrompt(formattedPrompt);
    while (true) {
      if (shouldStop) break;
      final (text, isDone) = llama!.getNext();
      final response = LlamaChatMessage('assistant', text);
      _messages.add(response);
      sendToParent(response);
      if (isDone) {
        shouldStop = true;
        sendToParent(LlamaChatDone());
      }
    }
    //reset shouldStop for next time...
    shouldStop = false;
  }
}
