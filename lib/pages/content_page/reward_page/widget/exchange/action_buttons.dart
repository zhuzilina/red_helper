import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onEarnPoints;
  final VoidCallback onViewDetails;

  const ActionButtons({
    super.key,
    required this.onEarnPoints,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.monetization_on),
              label: const Text('赚取积分', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onEarnPoints,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: onViewDetails,
            child: Text('积分明细 >', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}
