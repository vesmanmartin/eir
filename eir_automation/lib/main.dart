import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EIR LED Controller',
      home: ToggleButton(),
    );
  }
}

class ToggleButton extends StatefulWidget {
  @override
  ToggleButtonState createState() => ToggleButtonState();
}

class ToggleButtonState extends State<ToggleButton> {
  bool isOn = false;
  WebSocket? websocket;

  String connectionState = 'Connecting...';

  @override
  void initState() {
    super.initState();
    loadState();
    connectToServer();
  }

  Future<void> connectToServer() async {
    final uri = Uri.parse('ws://143.198.237.44:4321');
    const backoff = ConstantBackoff(Duration(seconds: 1));
    websocket = WebSocket(uri, backoff: backoff);

    websocket?.connection.listen((state) {
      setState(() {
        connectionState = state.toString(); // Update the state string
      });
      print('state: "$state"');
    });
    websocket?.messages.listen((message) {
      print('message: "$message"');
    });
  }

  void sendToServer(String message) {
    websocket?.send(message);
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isOn = prefs.getBool('isOn') ?? false;
    });
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isOn', isOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EIR LED Controller'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              connectionState,
              style: TextStyle(fontSize: 25.0),
            ),
            SizedBox(height: 90.0),
            Transform.scale(
              scale: 2.0, // Change this value to adjust the size of the switch
              child: Switch(
                value: isOn,
                onChanged: (value) {
                  setState(() {
                    isOn = value;
                    saveState();
                    sendToServer(isOn ? 'ON' : 'OFF');
                  });
                },
                activeColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    websocket?.close();
    super.dispose();
  }
}
