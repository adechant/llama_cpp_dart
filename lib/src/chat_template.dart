import 'package:llama_cpp_dart/llama_cpp_dart.dart';

enum LlmChatTemplate {
  chatml,
  llama2,
  llama2Sys,
  llama2SysBos,
  llama2SysStrip,
  mistralV1,
  mistralV3,
  mistralV3Tekken,
  mistralV7,
  phi3,
  phi4,
  falcon3,
  zephyr,
  monarch,
  gemma,
  orion,
  openchat,
  vicuna,
  vicunaOrca,
  deepseek,
  deepseek2,
  deepseek3,
  commandR,
  llama3,
  chatgml3,
  chatgml4,
  glmedge,
  minicpm,
  exaone3,
  rwkvWorld,
  granite,
  gigachat,
  megrez,
  unknown, // Add unknown for LLM_CHAT_TEMPLATE_UNKNOWN if it exists in C++ enum
}

const Map<String, LlmChatTemplate> llmChatTemplates = {
  "chatml": LlmChatTemplate.chatml,
  "llama2": LlmChatTemplate.llama2,
  "llama2-sys": LlmChatTemplate.llama2Sys,
  "llama2-sys-bos": LlmChatTemplate.llama2SysBos,
  "llama2-sys-strip": LlmChatTemplate.llama2SysStrip,
  "mistral-v1": LlmChatTemplate.mistralV1,
  "mistral-v3": LlmChatTemplate.mistralV3,
  "mistral-v3-tekken": LlmChatTemplate.mistralV3Tekken,
  "mistral-v7": LlmChatTemplate.mistralV7,
  "phi3": LlmChatTemplate.phi3,
  "phi4": LlmChatTemplate.phi4,
  "falcon3": LlmChatTemplate.falcon3,
  "zephyr": LlmChatTemplate.zephyr,
  "monarch": LlmChatTemplate.monarch,
  "gemma": LlmChatTemplate.gemma,
  "orion": LlmChatTemplate.orion,
  "openchat": LlmChatTemplate.openchat,
  "vicuna": LlmChatTemplate.vicuna,
  "vicuna-orca": LlmChatTemplate.vicunaOrca,
  "deepseek": LlmChatTemplate.deepseek,
  "deepseek2": LlmChatTemplate.deepseek2,
  "deepseek3": LlmChatTemplate.deepseek3,
  "command-r": LlmChatTemplate.commandR,
  "llama3": LlmChatTemplate.llama3,
  "chatglm3": LlmChatTemplate.chatgml3,
  "chatglm4": LlmChatTemplate.chatgml4,
  "glmedge": LlmChatTemplate.glmedge,
  "minicpm": LlmChatTemplate.minicpm,
  "exaone3": LlmChatTemplate.exaone3,
  "rwkv-world": LlmChatTemplate.rwkvWorld,
  "granite": LlmChatTemplate.granite,
  "gigachat": LlmChatTemplate.gigachat,
  "megrez": LlmChatTemplate.megrez,
};

LlmChatTemplate llmChatTemplateFromStr(String name) {
  LlmChatTemplate? template = llmChatTemplates[name];
  if (template == null) {
    throw Exception('Unknown template: $name');
  }
  return template;
}

LlmChatTemplate llmChatDetectTemplate(String tmpl) {
  try {
    return llmChatTemplateFromStr(tmpl);
  } catch (e) {
    // ignore,
  }

  bool tmplContains(String haystack) {
    return tmpl.contains(haystack);
  }

  if (tmplContains("<|im_start|>")) {
    return tmplContains("<|im_sep|>")
        ? LlmChatTemplate.phi4
        : LlmChatTemplate.chatml;
  } else if (tmpl.startsWith("mistral") || tmplContains("[INST]")) {
    if (tmplContains("[SYSTEM_PROMPT]")) {
      return LlmChatTemplate.mistralV7;
    } else if (
        // catches official 'v1' template
        tmplContains("' [INST] ' + system_message") ||
            // catches official 'v3' and 'v3-tekken' templates
            tmplContains("[AVAILABLE_TOOLS]")) {
      // Official mistral 'v1', 'v3' and 'v3-tekken' templates
      // See: https://github.com/mistralai/cookbook/blob/main/concept-deep-dive/tokenization/chat_templates.md
      // See: https://github.com/mistralai/cookbook/blob/main/concept-deep-dive/tokenization/templates.md
      if (tmplContains(" [INST]")) {
        return LlmChatTemplate.mistralV1;
      } else if (tmplContains("\"[INST]\"")) {
        return LlmChatTemplate.mistralV3Tekken;
      }
      return LlmChatTemplate.mistralV3;
    } else {
      // llama2 template and its variants
      // [variant] support system message
      // See: https://huggingface.co/blog/llama2#how-to-prompt-llama-2
      bool supportSystemMessage = tmplContains("<<SYS>>");
      bool addBosInsideHistory = tmplContains("bos_token + '[INST]");
      bool stripMessage = tmplContains("content.strip()");
      if (stripMessage) {
        return LlmChatTemplate.llama2SysStrip;
      } else if (addBosInsideHistory) {
        return LlmChatTemplate.llama2SysBos;
      } else if (supportSystemMessage) {
        return LlmChatTemplate.llama2Sys;
      } else {
        return LlmChatTemplate.llama2;
      }
    }
  } else if (tmplContains("<|assistant|>") && tmplContains("<|end|>")) {
    return LlmChatTemplate.phi3;
  } else if (tmplContains("<|assistant|>") && tmplContains("<|user|>")) {
    return tmplContains("</s>")
        ? LlmChatTemplate.falcon3
        : LlmChatTemplate.glmedge;
  } else if (tmplContains("<|user|>") && tmplContains("<|endoftext|>")) {
    return LlmChatTemplate.zephyr;
  } else if (tmplContains("bos_token + message['role']")) {
    return LlmChatTemplate.monarch;
  } else if (tmplContains("<start_of_turn>")) {
    return LlmChatTemplate.gemma;
  } else if (tmplContains("'\\n\\nAssistant: ' + eos_token")) {
    // OrionStarAI/Orion-14B-Chat
    return LlmChatTemplate.orion;
  } else if (tmplContains("GPT4 Correct ")) {
    // openchat/openchat-3.5-0106
    return LlmChatTemplate.openchat;
  } else if (tmplContains("USER: ") && tmplContains("ASSISTANT: ")) {
    // eachadea/vicuna-13b-1.1 (and Orca variant)
    if (tmplContains("SYSTEM: ")) {
      return LlmChatTemplate.vicunaOrca;
    }
    return LlmChatTemplate.vicuna;
  } else if (tmplContains("### Instruction:") && tmplContains("<|EOT|>")) {
    // deepseek-ai/deepseek-coder-33b-instruct
    return LlmChatTemplate.deepseek;
  } else if (tmplContains("<|START_OF_TURN_TOKEN|>") &&
      tmplContains("<|USER_TOKEN|>")) {
    // CohereForAI/c4ai-command-r-plus
    return LlmChatTemplate.commandR;
  } else if (tmplContains("<|start_header_id|>") &&
      tmplContains("<|end_header_id|>")) {
    return LlmChatTemplate.llama3;
  } else if (tmplContains("[gMASK]sop")) {
    // chatglm3-6b
    return LlmChatTemplate.chatgml3;
  } else if (tmplContains("[gMASK]<sop>")) {
    return LlmChatTemplate.chatgml4;
  } else if (tmplContains(r"<用户>")) {
    // Use raw string for special characters
    // MiniCPM-3B-OpenHermes-2.5-v2-GGUF
    return LlmChatTemplate.minicpm;
  } else if (tmplContains("'Assistant: ' + message['content'] + eos_token")) {
    return LlmChatTemplate.deepseek2;
  } else if (tmplContains("<｜Assistant｜>") &&
      tmplContains("<｜User｜>") &&
      tmplContains("<｜end▁of▁sentence｜>")) {
    return LlmChatTemplate.deepseek3;
  } else if (tmplContains("[|system|]") &&
      tmplContains("[|assistant|]") &&
      tmplContains("[|endofturn|]")) {
    // ref: https://huggingface.co/LGAI-EXAONE/EXAONE-3.0-7.8B-Instruct/discussions/8#66bae61b1893d14ee8ed85bb
    // EXAONE-3.0-7.8B-Instruct
    return LlmChatTemplate.exaone3;
  } else if (tmplContains("rwkv-world")) {
    return LlmChatTemplate.rwkvWorld;
  } else if (tmplContains("<|start_of_role|>")) {
    return LlmChatTemplate.granite;
  } else if (tmplContains(
      "message['role'] + additional_special_tokens[0] + message['content'] + additional_special_tokens[1]")) {
    return LlmChatTemplate.gigachat;
  } else if (tmplContains("<|role_start|>")) {
    return LlmChatTemplate.megrez;
  }
  return LlmChatTemplate.unknown;
}

String trim(String str) {
  return str.trim();
}

String llmChatApplyTemplate(
    LlmChatTemplate tmpl, LlamaChatMessage chat, bool addAss) {
  return llmChatsApplyTemplate(tmpl, [chat], addAss);
}

String llmChatsApplyTemplate(
  LlmChatTemplate tmpl,
  List<LlamaChatMessage> chat,
  bool addAss,
) {
  StringBuffer ss = StringBuffer();
  if (tmpl == LlmChatTemplate.chatml) {
    // chatml template
    for (var message in chat) {
      ss.write("<|im_start|>${message.role}\n${message.content}<|im_end|>\n");
    }
    if (addAss) {
      ss.write("<|im_start|>assistant\n");
    }
  } else if (tmpl == LlmChatTemplate.mistralV7) {
    // Official mistral 'v7' template
    // See: https://huggingface.co/mistralai/Mistral-Large-Instruct-2411#basic-instruct-template-v7
    for (var message in chat) {
      String role = message.role;
      String content = message.content;
      if (role == "system") {
        ss.write("[SYSTEM_PROMPT] $content[/SYSTEM_PROMPT]");
      } else if (role == "user") {
        ss.write("[INST] $content[/INST]");
      } else {
        ss.write(" $content</s>");
      }
    }
  } else if (tmpl == LlmChatTemplate.mistralV1 ||
      tmpl == LlmChatTemplate.mistralV3 ||
      tmpl == LlmChatTemplate.mistralV3Tekken) {
    // See: https://github.com/mistralai/cookbook/blob/main/concept-deep-dive/tokenization/chat_templates.md
    // See: https://github.com/mistralai/cookbook/blob/main/concept-deep-dive/tokenization/templates.md
    String leadingSpace = tmpl == LlmChatTemplate.mistralV1 ? " " : "";
    String trailingSpace = tmpl == LlmChatTemplate.mistralV3Tekken ? "" : " ";
    bool trimAssistantMessage = tmpl == LlmChatTemplate.mistralV3;
    bool isInsideTurn = false;
    for (var message in chat) {
      if (!isInsideTurn) {
        ss.write("$leadingSpace[INST]$trailingSpace");
        isInsideTurn = true;
      }
      String role = message.role;
      String content = message.content;
      if (role == "system") {
        ss.write("$content\n\n");
      } else if (role == "user") {
        ss.write("$content$leadingSpace[/INST]");
      } else {
        ss.write(
            "$trailingSpace${trimAssistantMessage ? trim(content) : content}</s>");
        isInsideTurn = false;
      }
    }
  } else if (tmpl == LlmChatTemplate.llama2 ||
      tmpl == LlmChatTemplate.llama2Sys ||
      tmpl == LlmChatTemplate.llama2SysBos ||
      tmpl == LlmChatTemplate.llama2SysStrip) {
    // llama2 template and its variants
    // [variant] support system message
    // See: https://huggingface.co/blog/llama2#how-to-prompt-llama-2
    bool supportSystemMessage = tmpl != LlmChatTemplate.llama2;
    // [variant] add BOS inside history
    bool addBosInsideHistory = tmpl == LlmChatTemplate.llama2SysBos;
    // [variant] trim spaces from the input message
    bool stripMessage = tmpl == LlmChatTemplate.llama2SysStrip;
    // construct the prompt
    bool isInsideTurn = true; // skip BOS at the beginning
    ss.write("[INST] ");
    for (var message in chat) {
      String content = stripMessage ? trim(message.content) : message.content;
      String role = message.role;
      if (!isInsideTurn) {
        isInsideTurn = true;
        ss.write(addBosInsideHistory ? "<s>[INST] " : "[INST] ");
      }
      if (role == "system") {
        if (supportSystemMessage) {
          ss.write("<<SYS>>\n$content\n<</SYS>>\n\n");
        } else {
          // if the model does not support system message, we still include it in the first message, but without <<SYS>>
          ss.write("$content\n");
        }
      } else if (role == "user") {
        ss.write("$content [/INST]");
      } else {
        ss.write("$content</s>");
        isInsideTurn = false;
      }
    }
  } else if (tmpl == LlmChatTemplate.phi3) {
    // Phi 3
    for (var message in chat) {
      String role = message.role;
      ss.write("<|$role|>\n${message.content}<|end|>\n");
    }
    if (addAss) {
      ss.write("<|assistant|>\n");
    }
  } else if (tmpl == LlmChatTemplate.phi4) {
    // chatml template
    for (var message in chat) {
      ss.write(
          "<|im_start|>${message.role}<|im_sep|>${message.content}<|im_end|>");
    }
    if (addAss) {
      ss.write("<|im_start|>assistant<|im_sep|>");
    }
  } else if (tmpl == LlmChatTemplate.falcon3) {
    // Falcon 3
    for (var message in chat) {
      String role = message.role;
      ss.write("<|$role|>\n${message.content}\n");
    }
    if (addAss) {
      ss.write("<|assistant|>\n");
    }
  } else if (tmpl == LlmChatTemplate.zephyr) {
    // zephyr template
    for (var message in chat) {
      ss.write("<|${message.role}|>\n${message.content}<|endoftext|>\n");
    }
    if (addAss) {
      ss.write("<|assistant|>\n");
    }
  } else if (tmpl == LlmChatTemplate.monarch) {
    // mlabonne/AlphaMonarch-7B template (the <s> is included inside history)
    for (var message in chat) {
      String bos =
          (message == chat.first) ? "" : "<s>"; // skip BOS for first message
      ss.write("$bos${message.role}\n${message.content}</s>\n");
    }
    if (addAss) {
      ss.write("<s>assistant\n");
    }
  } else if (tmpl == LlmChatTemplate.gemma) {
    // google/gemma-7b-it
    String systemPrompt = "";
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        // there is no system message for gemma, but we will merge it with user prompt, so nothing is broken
        systemPrompt = trim(message.content);
        continue;
      }
      // in gemma, "assistant" is "model"
      role = role == "assistant" ? "model" : message.role;
      ss.write("<start_of_turn>$role\n");
      if (systemPrompt.isNotEmpty && role != "model") {
        ss.write("$systemPrompt\n\n");
        systemPrompt = "";
      }
      ss.write("${trim(message.content)}<end_of_turn>\n");
    }
    if (addAss) {
      ss.write("<start_of_turn>model\n");
    }
  } else if (tmpl == LlmChatTemplate.orion) {
    // OrionStarAI/Orion-14B-Chat
    String systemPrompt = "";
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        // there is no system message support, we will merge it with user prompt
        systemPrompt = message.content;
        continue;
      } else if (role == "user") {
        ss.write("Human: ");
        if (systemPrompt.isNotEmpty) {
          ss.write("$systemPrompt\n\n");
          systemPrompt = "";
        }
        ss.write("${message.content}\n\nAssistant: </s>");
      } else {
        ss.write("${message.content}</s>");
      }
    }
  } else if (tmpl == LlmChatTemplate.openchat) {
    // openchat/openchat-3.5-0106,
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write("${message.content}<|end_of_turn|>");
      } else {
        role = role[0].toUpperCase() + role.substring(1); // toupper first char
        ss.write("GPT4 Correct $role: ${message.content}<|end_of_turn|>");
      }
    }
    if (addAss) {
      ss.write("GPT4 Correct Assistant:");
    }
  } else if (tmpl == LlmChatTemplate.vicuna ||
      tmpl == LlmChatTemplate.vicunaOrca) {
    // eachadea/vicuna-13b-1.1 (and Orca variant)
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        // Orca-Vicuna variant uses a system prefix
        if (tmpl == LlmChatTemplate.vicunaOrca) {
          ss.write("SYSTEM: ${message.content}\n");
        } else {
          ss.write("${message.content}\n\n");
        }
      } else if (role == "user") {
        ss.write("USER: ${message.content}\n");
      } else if (role == "assistant") {
        ss.write("ASSISTANT: ${message.content}</s>\n");
      }
    }
    if (addAss) {
      ss.write("ASSISTANT:");
    }
  } else if (tmpl == LlmChatTemplate.deepseek) {
    // deepseek-ai/deepseek-coder-33b-instruct
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write(message.content);
      } else if (role == "user") {
        ss.write("### Instruction:\n${message.content}\n");
      } else if (role == "assistant") {
        ss.write("### Response:\n${message.content}\n<|EOT|>\n");
      }
    }
    if (addAss) {
      ss.write("### Response:\n");
    }
  } else if (tmpl == LlmChatTemplate.commandR) {
    // CohereForAI/c4ai-command-r-plus
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write(
            "<|START_OF_TURN_TOKEN|><|SYSTEM_TOKEN|>${trim(message.content)}<|END_OF_TURN_TOKEN|>");
      } else if (role == "user") {
        ss.write(
            "<|START_OF_TURN_TOKEN|><|USER_TOKEN|>${trim(message.content)}<|END_OF_TURN_TOKEN|>");
      } else if (role == "assistant") {
        ss.write(
            "<|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>${trim(message.content)}<|END_OF_TURN_TOKEN|>");
      }
    }
    if (addAss) {
      ss.write("<|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>");
    }
  } else if (tmpl == LlmChatTemplate.llama3) {
    // Llama 3
    for (var message in chat) {
      String role = message.role;
      ss.write(
          "<|start_header_id|>$role<|end_header_id|>\n\n${trim(message.content)}<|eot_id|>");
    }
    if (addAss) {
      ss.write("<|start_header_id|>assistant<|end_header_id|>\n\n");
    }
  } else if (tmpl == LlmChatTemplate.chatgml3) {
    // chatglm3-6b
    ss.write("[gMASK]sop");
    for (var message in chat) {
      String role = message.role;
      ss.write("<|$role|>\n ${message.content}");
    }
    if (addAss) {
      ss.write("<|assistant|>");
    }
  } else if (tmpl == LlmChatTemplate.chatgml4) {
    ss.write("[gMASK]<sop>");
    for (var message in chat) {
      String role = message.role;
      ss.write("<|$role|>\n${message.content}");
    }
    if (addAss) {
      ss.write("<|assistant|>");
    }
  } else if (tmpl == LlmChatTemplate.glmedge) {
    for (var message in chat) {
      String role = message.role;
      ss.write("<|$role|>\n${message.content}");
    }
    if (addAss) {
      ss.write("<|assistant|>");
    }
  } else if (tmpl == LlmChatTemplate.minicpm) {
    // MiniCPM-3B-OpenHermes-2.5-v2-GGUF
    for (var message in chat) {
      String role = message.role;
      if (role == "user") {
        ss.write("<用户>");
        ss.write(trim(message.content));
        ss.write("<AI>");
      } else {
        ss.write(trim(message.content));
      }
    }
  } else if (tmpl == LlmChatTemplate.deepseek2) {
    // DeepSeek-V2
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write("${message.content}\n\n");
      } else if (role == "user") {
        ss.write("User: ${message.content}\n\n");
      } else if (role == "assistant") {
        // Assuming LU8("<｜end of sentence｜>") is just a UTF-8 encoded string literal
        ss.write("Assistant: ${message.content}<｜end▁of▁sentence｜>");
      }
    }
    if (addAss) {
      ss.write("Assistant:");
    }
  } else if (tmpl == LlmChatTemplate.deepseek3) {
    // DeepSeek-V3
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write("${message.content}\n\n");
      } else if (role == "user") {
        // Assuming LU8("<｜User｜>") is just a UTF-8 encoded string literal
        ss.write("<｜User｜>${message.content}");
      } else if (role == "assistant") {
        // Assuming LU8("<｜Assistant｜>") and LU8("<｜end of sentence｜>") are UTF-8 string literals
        ss.write("<｜Assistant｜>${message.content}<｜end▁of▁sentence｜>");
      }
    }
    if (addAss) {
      ss.write("<｜Assistant｜>");
    }
  } else if (tmpl == LlmChatTemplate.exaone3) {
    // ref: https://huggingface.co/LGAI-EXAONE/EXAONE-3.0-7.8B-Instruct/discussions/8#66bae61b1893d14ee8ed85bb
    // EXAONE-3.0-7.8B-Instruct
    for (var message in chat) {
      String role = message.role;
      if (role == "system") {
        ss.write("[|system|]${trim(message.content)}[|endofturn|]\n");
      } else if (role == "user") {
        ss.write("[|user|]${trim(message.content)}\n");
      } else if (role == "assistant") {
        ss.write("[|assistant|]${trim(message.content)}[|endofturn|]\n");
      }
    }
    if (addAss) {
      ss.write("[|assistant|]");
    }
  } else if (tmpl == LlmChatTemplate.rwkvWorld) {
    // this template requires the model to have "\n\n" as EOT token
    for (var message in chat) {
      String role = message.role;
      if (role == "user") {
        ss.write("User: ${message.content}\n\nAssistant:");
      } else {
        ss.write("${message.content}\n\n");
      }
    }
  } else if (tmpl == LlmChatTemplate.granite) {
    // IBM Granite template
    for (var message in chat) {
      String role = message.role;
      ss.write("<|start_of_role|>$role<|end_of_role|>");
      if (role == "assistant_tool_call") {
        ss.write("<|tool_call|>");
      }
      ss.write("${message.content}<|end_of_text|>\n");
    }
    if (addAss) {
      ss.write("<|start_of_role|>assistant<|end_of_role|>\n");
    }
  } else if (tmpl == LlmChatTemplate.gigachat) {
    // GigaChat template
    bool hasSystem = chat.isNotEmpty && chat[0].role == "system";

    // Handle system message if present
    if (hasSystem) {
      ss.write("<s>${chat[0].content}<|message_sep|>");
    } else {
      ss.write("<s>");
    }

    // Process remaining messages
    for (int i = hasSystem ? 1 : 0; i < chat.length; i++) {
      String role = chat[i].role;
      if (role == "user") {
        ss.write("user<|role_sep|>${chat[i].content}<|message_sep|>"
            "available functions<|role_sep|>[]<|message_sep|>");
      } else if (role == "assistant") {
        ss.write("assistant<|role_sep|>${chat[i].content}<|message_sep|>");
      }
    }

    // Add generation prompt if needed
    if (addAss) {
      ss.write("assistant<|role_sep|>");
    }
  } else if (tmpl == LlmChatTemplate.megrez) {
    // Megrez template
    for (var message in chat) {
      String role = message.role;
      ss.write("<|role_start|>$role<|role_end|>${message.content}<|turn_end|>");
    }

    if (addAss) {
      ss.write("<|role_start|>assistant<|role_end|>");
    }
  } else {
    // template not supported
    return '';
  }
  return ss.toString();
}
