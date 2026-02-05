import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:async';

// Boilerplate

class Fruit {
  String emoji;
  double x, y, velocityX, velocityY;

  Fruit({
    required this.emoji,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
  });

  void updatePhysics(Duration deltaTime) {
    // Vel
    double deltaTimeSeconds = deltaTime.inMilliseconds / 1000;

    x += velocityX * deltaTimeSeconds; // pos = vel * tempo
    y += velocityY * deltaTimeSeconds;

    // Gravity
    double gravity = 1000;

    velocityY += gravity * deltaTimeSeconds; // vel = acel * tempo
  }

  bool isOffScreen(Size screenSize) => y > screenSize.height;

  static Fruit random(Size size) {
    const List<String> fruitEmojis = [
      '🍎',
      '🍊',
      '🍌',
      '🍇',
      '🍓',
      '🥝',
      '🍑',
      '🍒',
    ];

    final emoji = fruitEmojis[Random().nextInt(fruitEmojis.length)];

    const double velocityXRange = 200;
    const double minVelocityY = -800;
    const double velocityYRange = 300;

    final startX = Random().nextDouble() * size.width;
    final startY = size.height;
    final velocityX = (Random().nextDouble() - 0.5) * velocityXRange;
    final velocityY = minVelocityY - Random().nextDouble() * velocityYRange;

    return Fruit(
      emoji: emoji,
      x: startX,
      y: startY,
      velocityX: velocityX,
      velocityY: velocityY,
    );
  }
}

class SlicePainter extends CustomPainter {
  final List<Offset> sliceTrail;

  SlicePainter(this.sliceTrail);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 1; i < sliceTrail.length; i++) {
      canvas.drawLine(sliceTrail[i - 1], sliceTrail[i], Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Boilerplate

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int score = 0, lives = 3;
  List<Fruit> fruits = [];
  Timer? physicsTimer, spawnTimer, sliceTrailTimer;
  List<Offset> sliceTrail = [];

  @override
  void initState() {
    spawnTimer = Timer.periodic(
      Duration(milliseconds: 1000),
      (e) => spawnFruit(),
    );

    physicsTimer = Timer.periodic(
      Duration(milliseconds: 16),
      (e) => updateFruits(),
    );

    sliceTrailTimer = Timer.periodic(
      Duration(milliseconds: 12),
      (e) => removeTrail(),
    );

    super.initState();
  }

  @override
  void dispose() {
    spawnTimer?.cancel();
    physicsTimer?.cancel();
    sliceTrailTimer?.cancel();

    super.dispose();
  }

  void spawnFruit() {
    setState(() {
      fruits.add(Fruit.random(MediaQuery.of(context).size));
    });
  }

  void updateFruits() {
    setState(() {
      for (var fruit in fruits) {
        fruit.updatePhysics(Duration(milliseconds: 16));
      }

      fruits.removeWhere((fruit) {
        if (fruit.isOffScreen(MediaQuery.of(context).size)) {
          lives--;

          if (lives <= 0) {
            gameOver();
          }

          return true;
        }

        return false;
      });
    });
  }

  void slice(Offset point) {
    setState(() {
      sliceTrail.add(point);
    });

    for (var fruit in fruits) {
      final dx = (point.dx - fruit.x).abs();
      final dy = (point.dy - fruit.y).abs();

      if (dx < 30 && dy < 30) {
        setState(() {
          fruits.remove(fruit);
          score++;
        });
      }
    }
  }

  void removeTrail() {
    if (sliceTrail.isNotEmpty) {
      setState(() {
        sliceTrail.removeAt(0);
      });
    }
  }

  void gameOver() {
    physicsTimer?.cancel();
    spawnTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('GAME OVER'),
        content: Text('Score: $score'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) => slice(event.localPosition),
        child: Stack(
          children: [
            CustomPaint(painter: SlicePainter(sliceTrail), size: Size.infinite),

            for (var fruit in fruits)
              Positioned(
                left: fruit.x,
                top: fruit.y,
                child: Text(fruit.emoji, style: TextStyle(fontSize: 60)),
              ),

            Positioned(top: 20, left: 50, child: Text('Score $score')),
            Positioned(top: 20, right: 50, child: Text('Vidas $lives')),
          ],
        ),
      ),
    );
  }
}
