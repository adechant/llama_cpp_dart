import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'dart:async';
import 'dart:isolate';

enum LlamaGenerationState {
  ready('Ready'),
  thinking('Thinking'),
  generating('Generating'),
  interrupting('Interrupting'),
  error('Error');

  const LlamaGenerationState(this.name);
  final String name;

  @override
  String toString() => name;
}

class LLMProvider extends ChangeNotifier {
  final ContextParams ctxParams;
  final SamplerParams samplerParams;
  List<LlamaChatMessage> messages = [];
  StreamController<String>? _controller;
  StreamController<String>? _thinkController;
  LlamaGenerationState _state = LlamaGenerationState.ready;
  LlamaGenerationState get state => _state;
  String? _modelPath;
  final Pointer<Uint8> _interruptFlag = calloc<Uint8>(1);

  Isolate? _child;
  ReceivePort? _parentReceivePort;
  SendPort? _parentSendPort;

  LLMProvider()
      : ctxParams = ContextParams(),
        samplerParams = SamplerParams() {
    ctxParams.nCtx = 8192;
    ctxParams.nBatch = 8192;
    ctxParams.nThreads = 8;
    //samplerParams.penaltyRepeat = 1.1;
    //samplerParams.temp = 0.6;
    ctxParams.nThreadsBatch = ctxParams.nThreads;
    _interruptFlag.value = 0;
  }

  @override
  void dispose() {
    _parentSendPort?.send(LlamaKill());
    _parentSendPort = null;
    _parentReceivePort?.close();
    _controller?.close();
    _thinkController?.close();
    _child?.kill();
    // Safely free memory after isolate is killed
    calloc.free(_interruptFlag);
    super.dispose();
  }

  void interrupt() {
    if (state == LlamaGenerationState.generating) {
      //use pointer to set interrupt flag
      _interruptFlag.value = 1;
      updateState(LlamaGenerationState.interrupting);
    }
  }

  void clear() {
    messages.clear();
    _parentSendPort?.send(LlamaClear());
    _interruptFlag.value = 0;
  }

  //************************************ PARENT ************************************/

  Future<bool> load({required String path}) async {
    if (_child == null) {
      _modelPath = path;
      _parentReceivePort = ReceivePort();
      _child =
          await Isolate.spawn(LlamaChild.process, _parentReceivePort!.sendPort);

      _parentReceivePort!.listen((data) async {
        if (data is SendPort) {
          _parentSendPort = data;
          _interruptFlag.value = 0;
          _parentSendPort?.send(
            LlamaLoad(
              path: path,
              modelParams: ModelParams(),
              contextParams: ctxParams,
              samplingParams: samplerParams,
              checkInterruptPointer: _interruptFlag.address,
            ),
          );
        } else if (data is LlamaCommand) {
          switch (data) {
            case LlamaChatMessage():
              _parseResponse(data);
              break;
            case LlamaChatError(:final error):
              _controller?.addError(error);
              _child?.kill();
              _child = null;
              updateState(LlamaGenerationState.error);
              break;
            case LlamaChatDone():
              await _controller?.close();
              await _thinkController?.close();
              _controller = null;
              _thinkController = null;
              updateState(LlamaGenerationState.ready);
              break;
            case LLamaInterrupted():
              updateState(LlamaGenerationState.ready);
              _interruptFlag.value = 0;
              break;
            default:
              break;
          }
        }
      });
    } else if (_modelPath != path) {
      _modelPath = path;
      _parentSendPort?.send(LlamaDispose());
      _parentSendPort?.send(
        LlamaLoad(
          path: path,
          modelParams: ModelParams(),
          contextParams: ctxParams,
          samplingParams: samplerParams,
          checkInterruptPointer: _interruptFlag.address,
        ),
      );
      updateState(LlamaGenerationState.ready);
    }
    return true;
  }

  void sendSystemPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('system', prompt);
    messages.add(msg);
    _parentSendPort?.send(msg);
  }

  (Stream<String>, Stream<String>) sendUserPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('user', prompt);
    messages.add(msg);
    _parentSendPort?.send(msg);
    _controller = StreamController<String>.broadcast();
    _thinkController = StreamController<String>.broadcast();
    updateState(LlamaGenerationState.generating);
    return (_controller!.stream, _thinkController!.stream);
  }

  void _parseResponse(LlamaChatMessage response) {
    //messages.add(response); todo add to messages once completed message received
    //todo use regexp to check if thinking or generating in case response returns multiple text sequences
    if (response.content.contains('<think>')) {
      final String beforeThinking =
          response.content.substring(0, response.content.indexOf('<think>'));
      final String afterThinking =
          response.content.substring(response.content.indexOf('<think>'));
      updateState(LlamaGenerationState.thinking);
      if (beforeThinking.isNotEmpty) {
        _controller?.add(beforeThinking);
      }
      if (afterThinking.isNotEmpty) {
        _thinkController?.add(afterThinking);
      }
    } else if (response.content.contains('</think>')) {
      final String beforeThinkingEnd = response.content.substring(
        0,
        response.content.indexOf('</think>') + '</think>'.length,
      );
      final String afterThinkingEnd = response.content
          .substring(response.content.indexOf('</think>') + '</think>'.length);
      updateState(LlamaGenerationState.generating);
      if (afterThinkingEnd.isNotEmpty) {
        _controller?.add(afterThinkingEnd);
      }
      if (beforeThinkingEnd.isNotEmpty) {
        _thinkController?.add(beforeThinkingEnd);
      }
    } else if (_state == LlamaGenerationState.thinking) {
      updateState(LlamaGenerationState.thinking);
      _thinkController?.add(response.content);
    } else {
      updateState(LlamaGenerationState.generating);
      _controller?.add(response.content);
    }
  }

  void updateState(LlamaGenerationState state) {
    if (_state == state) return;
    _state = state;
    notifyListeners();
  }
}
