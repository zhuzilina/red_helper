import 'package:flutter/material.dart';
import 'lib/pages/content_page/super_page/super_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperPage Fix Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestPage(),
    );
  }
}

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SuperPage Fix Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('点击按钮测试SuperPage', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '焦裕禄'),
                  ),
                );
              },
              child: Text('打开SuperPage (焦裕禄)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '邓小平'),
                  ),
                );
              },
              child: Text('打开SuperPage (邓小平)'),
            ),
          ],
        ),
      ),
    );
  }
}
