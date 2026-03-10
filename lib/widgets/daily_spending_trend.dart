import 'package:flutter/material.dart';
import '../cubit/expense_state.dart';

class DailySpendingTrend extends StatelessWidget {
  final ExpenseState state;

  const DailySpendingTrend({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: TrendLinePainter(dailyTotals: state.dailyTotals),
        size: Size.infinite,
      ),
    );
  }
}

class TrendLinePainter extends CustomPainter {
  final Map<DateTime, double> dailyTotals;

  TrendLinePainter({required this.dailyTotals});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyTotals.isEmpty) {
      // Draw empty state message
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No spending data available',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    final maxAmount = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    // Prevent division by zero
    if (maxAmount == 0) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < sortedDays.length; i++) {
      final x = (i / (sortedDays.length - 1)) * size.width;
      // Add some padding at the top (20% of height) so the line doesn't touch the top edge
      final y =
          size.height -
          (dailyTotals[sortedDays[i]]! / maxAmount) * size.height * 0.8;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw data points
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.blue);
    }

    if (sortedDays.isNotEmpty) {
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw y-axis labels (optional)
    final labelPainter = TextPainter(
      text: const TextSpan(
        text: '300',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();

    // Draw at the top
    labelPainter.paint(canvas, const Offset(5, 5));

    // Draw middle label
    labelPainter.text = const TextSpan(
      text: '200',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(5, size.height / 2 - labelPainter.height / 2),
    );

    // Draw bottom label
    labelPainter.text = const TextSpan(
      text: '100',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(5, size.height - labelPainter.height - 5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is TrendLinePainter) {
      return oldDelegate.dailyTotals != dailyTotals;
    }
    return true;
  }
}
