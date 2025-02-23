import 'dart:async';
import 'dart:isolate';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:typed_isolate/typed_isolate.dart';

class LlamaParent {
  final _parent = IsolateParent<LlamaCommand, LlamaResponse>();
  Isolate? _child;
  bool get isInitialized => _child != null;
  StreamSubscription<LlamaResponse>? _subscription;
  List<LlamaChatMessage> messages = [];
  final LlamaLoad loadCommand;
  LlamaParent(this.loadCommand);
  StreamController<String>? _controller;

  void _onData(LlamaResponse data) async {
    switch (data) {
      case LlamaChatMessage():
        _parseResponse(data);
        break;
      case LlamaChatError(:final error):
        _controller?.addError(error);
        break;
      case LlamaChatDone():
        await _controller?.close();
        _controller = null;
        break;
    }
  }

  void _parseResponse(LlamaChatMessage response) {
    messages.add(response);
    _controller?.add(response.content);
  }

  Future<void> init() async {
    _parent.init();
    _subscription = _parent.stream.listen(_onData);
    _child?.kill();
    _child = await _parent.spawn(LlamaChild());
    _parent.sendToChild(
        data: LlamaInit(Llama.libraryPath, loadCommand.modelParams,
            loadCommand.contextParams, loadCommand.samplingParams),
        id: 1);
    _parent.sendToChild(data: loadCommand, id: 1);
  }

  void sendSystemPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('system', prompt);
    messages.add(msg);
    _parent.sendToChild(id: 1, data: msg);
  }

  Stream<String> sendUserPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('user', prompt);
    messages.add(msg);
    _parent.sendToChild(id: 1, data: msg);
    _controller = StreamController<String>.broadcast();
    return _controller!.stream;
  }

  void stop() => _parent.sendToChild(id: 1, data: LlamaStop());

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller?.close();
    _parent.sendToChild(id: 1, data: LlamaClear());
    _child?.kill();
    _parent.dispose();
    _child = null;
  }
}
