import 'dart:async';
import 'dart:isolate';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:typed_isolate/typed_isolate.dart';

enum LlamaGenerationState {
  ready('Ready'),
  thinking('Thinking'),
  generating('Generating'),
  error('Error');

  const LlamaGenerationState(this.name);
  final String name;

  @override
  String toString() => name;
}

class LlamaParent {
  final _parent = IsolateParent<LlamaCommand, LlamaResponse>();
  Isolate? _child;
  LlamaChild? _llamaChild;
  bool get isInitialized => _child != null;
  StreamSubscription<LlamaResponse>? _subscription;
  List<LlamaChatMessage> messages = [];
  final LlamaLoad loadCommand;
  LlamaParent(this.loadCommand);
  StreamController<String>? _controller;
  StreamController<String>? _thinkController;
  LlamaGenerationState _state = LlamaGenerationState.ready;
  LlamaGenerationState get state => _state;
  StreamController<LlamaGenerationState>? _stateController;
  int _generationCount = 0;
  int get generationCount => _generationCount;

  void _onData(LlamaResponse data) async {
    switch (data) {
      case LlamaChatMessage():
        _parseResponse(data);
        break;
      case LlamaChatError(:final error):
        _controller?.addError(error);
        _stateController?.add(LlamaGenerationState.ready);
        break;
      case LlamaChatDone():
        await _controller?.close();
        await _thinkController?.close();
        _controller = null;
        _thinkController = null;
        _state = LlamaGenerationState.ready;
        _stateController?.add(LlamaGenerationState.ready);
        break;
    }
  }

  void clear() {
    messages.clear();
    _parent.sendToChild(id: _generationCount, data: LlamaClear());
  }

  void _parseResponse(LlamaChatMessage response) {
    //messages.add(response); todo add to messages once completed message received
    //todo use regexp to check if thinking or generating in case response returns multiple text sequences
    if (response.content.contains('<think>')) {
      final String beforeThinking =
          response.content.substring(0, response.content.indexOf('<think>'));
      final String afterThinking =
          response.content.substring(response.content.indexOf('<think>'));
      _state = LlamaGenerationState.thinking;
      _stateController?.add(_state);
      if (beforeThinking.isNotEmpty) {
        _controller?.add(beforeThinking);
      }
      if (afterThinking.isNotEmpty) {
        _thinkController?.add(afterThinking);
      }
    } else if (response.content.contains('</think>')) {
      final String beforeThinkingEnd = response.content.substring(
          0, response.content.indexOf('</think>') + '</think>'.length);
      final String afterThinkingEnd = response.content
          .substring(response.content.indexOf('</think>') + '</think>'.length);
      _state = LlamaGenerationState.generating;
      _stateController?.add(_state);
      if (afterThinkingEnd.isNotEmpty) {
        _controller?.add(afterThinkingEnd);
      }
      if (beforeThinkingEnd.isNotEmpty) {
        _thinkController?.add(beforeThinkingEnd);
      }
    } else if (_state == LlamaGenerationState.thinking) {
      _thinkController?.add(response.content);
    } else {
      _controller?.add(response.content);
    }
  }

  Future<Stream<LlamaGenerationState>> init() async {
    _parent.init();
    _subscription = _parent.stream.listen(_onData);
    _stateController = StreamController<LlamaGenerationState>.broadcast();
    _initChild();
    return _stateController!.stream;
  }

  void sendSystemPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('system', prompt);
    messages.add(msg);
    _parent.sendToChild(id: _generationCount, data: msg);
  }

  (Stream<String>, Stream<String>) sendUserPrompt(String prompt) {
    LlamaChatMessage msg = LlamaChatMessage('user', prompt);
    messages.add(msg);
    _parent.sendToChild(id: _generationCount, data: msg);
    _controller = StreamController<String>.broadcast();
    _thinkController = StreamController<String>.broadcast();
    return (_controller!.stream, _thinkController!.stream);
  }

  void _initChild() async {
    _child?.kill(priority: Isolate.immediate);
    _generationCount++;
    _llamaChild = LlamaChild(_generationCount);
    _child = await _parent.spawn(_llamaChild!);
    _parent.sendToChild(
        data: LlamaInit(Llama.libraryPath, loadCommand.modelParams,
            loadCommand.contextParams, loadCommand.samplingParams),
        id: _generationCount);
    _parent.sendToChild(data: loadCommand, id: _generationCount);
    _state = LlamaGenerationState.ready;
    _stateController?.add(_state);
  }

  void stop() async {
    _initChild();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller?.close();
    await _thinkController?.close();
    _parent.sendToChild(id: _generationCount, data: LlamaClear());
    _child?.kill(priority: Isolate.immediate);
    _parent.dispose();
    _child = null;
    _stateController?.close();
  }
}
