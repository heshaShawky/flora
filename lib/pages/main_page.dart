import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<MessageBubble> _data = [];
  bool _isLoading = false;
  late FlutterTts flutterTts;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool isAITalking = false;
  bool isActive = true;

  final SpeechToText _speechToText = SpeechToText();

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();
    _getDefaultEngine();
    _getDefaultVoice();

    Future.delayed(const Duration(seconds: 2), () => _startListening());
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  @override
  void initState() {
    _initSpeech();
    super.initState();
  }

  @override
  void dispose() {
    isActive = false;
    _stopListening();
    flutterTts.pause();
    super.dispose();
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async {
    // setState(() {
    //   // _lastWords = result.recognizedWords;

    //   // result.toFinal().recognizedWords;
    //   if (result.finalResult) {
    //     _data.add(MessageBubble(isMe: true, message: result.recognizedWords));
    //   }
    // });

    // print(result.recognizedWords);

    if (result.finalResult && result.isConfident()) {
      setState(() {
        isAITalking = true;
      });

      setState(() {
        _data.add(MessageBubble(isMe: true, message: result.recognizedWords));
        _isLoading = true;
      });

      final gemini = Gemini.instance;

      final response = await gemini.text(
        result.recognizedWords,
        // generationConfig: GenerationConfig()
      );

      if (response?.output != null) {
        // _stopListening();

        setState(() {
          _isLoading = false;
          _data.add(MessageBubble(isMe: false, message: '${response?.output}'));
        });
        await flutterTts.speak('${response?.output}');

        await flutterTts.awaitSpeakCompletion(true);

        isAITalking = false;
        _startListening();
      }
    }
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    initTts();

    _speechEnabled = await _speechToText.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (!isAITalking && isActive) {
          // _startListening();
          Future.delayed(const Duration(seconds: 1), _startListening);
        } else if (isAITalking) {
          _stopListening();
        }
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flora AI'),
        actions: [
          IconButton(
              onPressed: () {
                flutterTts.pause();
              },
              icon: const Icon(Icons.pause))
        ],
      ),
      body: _data.isEmpty
          ? const Center(
              child: Text('Start chating now, I am your asistant'),
            )
          : ListView(
              children: <Widget>[
                ..._data,
                // MessageBubble(isMe: false, message: 'Hello!'),
                // MessageBubble(isMe: true, message: 'Hi there!'),
                // MessageBubble(isMe: false, message: 'How are you?'),
              ],
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _isLoading
                ? LoadingAnimationWidget.staggeredDotsWave(
                    color: Theme.of(context).primaryColor,
                    size: 100,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;

  const MessageBubble({super.key, required this.isMe, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.blueGrey,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Html(
        data: message,
        style: {
          "body": Style(
            textAlign: isMe ? TextAlign.end : null,
            whiteSpace: WhiteSpace.pre,
            color: Colors.white,
          ),
        },
      ),
      // child: Text(
      //   message,
      //   style: const TextStyle(color: Colors.white),
      // ),
    );
  }
}
