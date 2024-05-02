import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final Gemini gemnini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");

  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "Assistant",
      profileImage:
      "https://t3.ftcdn.net/jpg/04/77/81/22/360_F_477812217_BVMns3ybwK4PHrUD3nGrwEL5lyxKmdik.jpg");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Asistant Chat",
        ),
      ),
      body: _builUI(),
    );
  }

  Widget _builUI() {
    return DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
              onPressed: sendMedia, icon: const Icon(Icons.add_a_photo_rounded))
        ]),
        currentUser: currentUser,
        onSend: sendMessage,
        messages: messages);
  }

  void sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemnini.streamGenerateContent(question,images: images,).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String respone = event.content?.parts?.fold(
              "",
                  (previousValue, element) =>
              "$previousValue ${element.text}") ??
              "";

          lastMessage.text += respone;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String respone = event.content?.parts?.fold(
              "",
                  (previousValue, element) =>
              "$previousValue ${element.text}") ??
              "";
          ChatMessage message = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: respone);
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void sendMedia() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          // text: "",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);

      sendMessage(chatMessage);
    }
  }
}