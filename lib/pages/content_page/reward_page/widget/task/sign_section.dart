import 'package:flutter/material.dart';
import 'date_grid.dart';
import 'progress_bar.dart';

class SignSection extends StatelessWidget {
  final bool hasSigned;
  final List<DateTime> signDates;
  final int continuousDays;
  final Function(DateTime) onSign;

  const SignSection({
    super.key,
    required this.hasSigned,
    required this.signDates,
    required this.continuousDays,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 26, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '签到赚积分',
                  style: TextStyle(
                    fontFamily: 'blockLetter',
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xffd80835),
                  ),
                ),
                SizedBox(
                  width: hasSigned ? 140 : 120,
                  height: 36,
                  child: ElevatedButton.icon(
                    label: Text(
                      hasSigned ? '今日已领取' : '立即领取',
                      style: const TextStyle(
                        fontFamily: 'blockLetter',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasSigned ? Colors.grey : const Color(0xffef856d),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: hasSigned ? null : () => onSign(DateTime.now()),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 28), child: DateGrid()),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProgressBar(continuousDays: continuousDays),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('images/chest.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
