import 'dart:isolate';
import 'dart:async';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaChild {
  static Future process(SendPort childSendPort) async {
    Llama? llama;
    LlmChatTemplate template = LlmChatTemplate.chatml;
    String systemPrompt = '';

    // Setup the ports and send our receive port back to the parent
    final childReceivePortSingle = ReceivePort();
    final childReceivePort = childReceivePortSingle.asBroadcastStream();
    childSendPort.send(childReceivePortSingle.sendPort);

    // Can call interrupt to stop transcription.
    Future interrupt() async {
      childSendPort.send(LLamaInterrupted());
      await childReceivePort.drain();
    }

    await for (final data in childReceivePort) {
      if (data is LlamaCommand) {
        try {
          switch (data) {
            case LlamaClear():
              llama?.clear();
              break;
            case LlamaLoad(
                :final path,
                :final modelParams,
                :final contextParams,
                :final samplingParams,
                :final checkInterruptPointer
              ):
              llama = Llama(path,
                  modelParamsDart: modelParams,
                  contextParamsDart: contextParams,
                  samplerParams: samplingParams,
                  checkInterruptPointerAddress: checkInterruptPointer,
                  onInterrupt: () async {
                childSendPort.send(LLamaInterrupted());
                await childReceivePort.drain();
              });
              template =
                  llmChatDetectTemplate(llama?.fetchChatTemplate() ?? '');
              break;
            case LlamaChatMessage():
              String formattedPrompt =
                  llmChatApplyTemplate(template, data, data.addAssistant);
              if (formattedPrompt.isEmpty) {
                break;
              }

              if (data.role == 'system') {
                systemPrompt = formattedPrompt;
                break;
              } else if (data.role == 'user') {
                formattedPrompt = '$systemPrompt$formattedPrompt';
              }

              Stream<String>? response = llama?.generate(
                formattedPrompt,
              );
              response?.listen(
                (text) {
                  final response = LlamaChatMessage('assistant', text);
                  childSendPort.send(response); // Send response to parent
                },
                onDone: () {
                  childSendPort.send(LlamaChatDone());
                },
                onError: (e) {
                  childSendPort
                      .send(LlamaChatError(error: 'Error generating text $e'));
                },
              );
              break;
            case LlamaDispose():
              llama?.dispose();
              llama = null;
            case LlamaKill():
              childReceivePortSingle.close();
              llama?.dispose();
              llama = null;
              Isolate.exit();
            default:
              break;
          }
        } catch (e) {
          //print('Child Isolate error: $e');
          childSendPort.send(LlamaChatError(error: 'Error: $e'));
        }
      }
    }
    //print('Child Isolate exiting');
  }
}
