import 'package:flutter/material.dart';

class AppBarContent extends StatelessWidget {
  int currentPoints;
  AppBarContent({super.key, required this.currentPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xfffcbfa6), Color(0xffffe7cd)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(200)),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 56,
            left: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '任务中心',
                style: TextStyle(
                  fontFamily: 'blockLetter',
                  color: Colors.black,
                  fontSize: 54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Image.asset('assets/images/chest.png', width: 32, height: 32),
                  Text(
                    ' $currentPoints',
                    style: TextStyle(
                      fontFamily: 'blockLetter',
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    ' 积分',
                    style: TextStyle(
                      fontFamily: 'blockLetter',
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
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
