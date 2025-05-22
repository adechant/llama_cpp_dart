import "package:llama_cpp_dart/llama_cpp_dart.dart";

sealed class LlamaCommand {}

class LlamaClear extends LlamaCommand {}

class LLamaInterrupt extends LlamaCommand {}

class LlamaDispose extends LlamaCommand {}

class LlamaKill extends LlamaCommand {}

class LlamaInit extends LlamaCommand {
  final String? libraryPath;
  final ModelParams modelParams;
  final ContextParams contextParams;
  final SamplerParams samplingParams;
  LlamaInit(this.libraryPath, this.modelParams, this.contextParams,
      this.samplingParams);
}

class LlamaLoad extends LlamaCommand {
  final String path;
  final ModelParams modelParams;
  final ContextParams contextParams;
  final SamplerParams samplingParams;
  LlamaLoad({
    required this.path,
    required this.modelParams,
    required this.contextParams,
    required this.samplingParams,
  });
}

sealed class LlamaResponse extends LlamaCommand {}

class LlamaChatMessage extends LlamaResponse {
  final String role;
  final String content;
  final bool addAssistant;

  LlamaChatMessage(this.role, this.content, [this.addAssistant = true]);
}

class LlamaChatError extends LlamaResponse {
  final String error;
  LlamaChatError({
    required this.error,
  });
}

class LlamaChatDone extends LlamaResponse {}

class LlamaReady extends LlamaResponse{}
