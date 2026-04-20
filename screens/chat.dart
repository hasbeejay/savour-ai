import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:savourai/services/chatservice.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    messages.clear();
    // Optional: Send welcome message
    // chatFn("Hello! Give a cooking tip");
  }

  chatFn(String chatMsg) async {
    if (chatMsg.trim().isEmpty) return;

    controller.clear();
    setState(() {
      _isLoading = true;
      messages.add({"role": "user", "content": chatMsg.trim()});
    });

    try {
      // This should call ChefBotService
      var chat = await ChefBotService().sendMessage(chatMsg);

      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        messages.add({"role": "system", "content": chat});
        _isLoading = false;
      });
    } catch (e) {
      print("Chat error: $e");
      setState(() {
        messages.add({
          "role": "system",
          "content": "The chef is thinking... Try asking about pasta, chicken, or cooking tips!"
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/chatBackground.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea( // Wrapped with SafeArea
          child: Stack(
            children: [
              // Dark overlay for better text readability
              Positioned.fill(
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: const Color.fromARGB(115, 0, 0, 0),
                ),
              ),
              Column(
                children: [
                  // App Bar - now has proper spacing from status bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange[800],
                          child: Icon(Icons.restaurant_menu, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ChefBot",
                              style: GoogleFonts.ptSans(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Your Cooking Assistant",
                              style: GoogleFonts.ptSans(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      reverse: false,
                      padding: EdgeInsets.all(12),
                      itemCount: messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && _isLoading) {
                          // Loading indicator
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(left: 8, top: 8, bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(228, 241, 204, 149),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Thinking...",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final message = messages[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          title: message['role'] == "user"
                              ? Align(
                            alignment: Alignment.bottomRight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Container(
                                  color: const Color.fromARGB(255, 213, 159, 79),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      message['content'],
                                      style: GoogleFonts.ptSans(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                              : Align(
                            alignment: Alignment.centerLeft,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                              child: Container(
                                color: const Color.fromARGB(228, 241, 204, 149),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: MarkdownBody(
                                    data: message['content'],
                                    styleSheet: MarkdownStyleSheet(
                                      p: GoogleFonts.ptSans(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                      a: TextStyle(color: Colors.blue),
                                      strong: TextStyle(fontWeight: FontWeight.bold),
                                      em: TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white)),
                      color: const Color.fromARGB(180, 63, 42, 22),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.multiline,
                            cursorColor: Colors.white,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white70),
                              hintText: "Ask about cooking, recipes, tips...",
                              contentPadding: EdgeInsets.only(left: 20, top: 15),
                            ),
                            controller: controller,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                chatFn(value.trim());
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => chatFn(controller.text.trim()),
                            icon: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Icon(Icons.send_rounded, size: 30, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}