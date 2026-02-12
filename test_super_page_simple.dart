import 'package:flutter/material.dart';
import 'lib/pages/content_page/super_page/super_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperPage 优化测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SuperPage 优化测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SuperPage 优化测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('点击按钮测试不同主题的SuperPage', style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                print("🔄 测试导航到SuperPage - 焦裕禄");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '焦裕禄'),
                  ),
                );
              },
              child: Text('测试焦裕禄主题'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("🔄 测试导航到SuperPage - 邓小平");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '邓小平'),
                  ),
                );
              },
              child: Text('测试邓小平主题'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("🔄 测试导航到SuperPage - 毛泽东");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '毛泽东'),
                  ),
                );
              },
              child: Text('测试毛泽东主题'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("🔄 测试导航到SuperPage - 不存在的主题");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SuperPage(topicName: '不存在的主题'),
                  ),
                );
              },
              child: Text('测试错误处理'),
            ),
          ],
        ),
      ),
    );
  }
}
