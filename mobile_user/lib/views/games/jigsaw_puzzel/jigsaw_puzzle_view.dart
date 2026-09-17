import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class JigsawPuzzleView extends StatefulWidget {
  final String imageUrl;
  final int gridSize;

  const JigsawPuzzleView({
    Key? key,
    this.imageUrl = 'https://images.unsplash.com/photo-1543373014-cfe4f4bc1cdf?q=80&w=1000&auto=format&fit=crop',
    this.gridSize = 3,
  }) : super(key: key);

  @override
  State<JigsawPuzzleView> createState() => _JigsawPuzzleViewState();
}

class _JigsawPuzzleViewState extends State<JigsawPuzzleView> {
  List<int> currentOrder = [];
  List<int> correctOrder = [];
  bool isPlaying = false;
  int moves = 0;
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _initializeBoard() {
    int totalPieces = widget.gridSize * widget.gridSize;
    correctOrder = List.generate(totalPieces, (index) => index);
    currentOrder = List.from(correctOrder);
    moves = 0;
    seconds = 0;
    isPlaying = false;
    timer?.cancel();
    setState(() {});
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      moves = 0;
      seconds = 0;
      currentOrder.shuffle(Random());
      
      // Ensure it's not solved by pure chance
      bool isSolved = true;
      for (int i = 0; i < currentOrder.length; i++) {
        if (currentOrder[i] != correctOrder[i]) {
          isSolved = false;
          break;
        }
      }
      if (isSolved) {
        int temp = currentOrder[0];
        currentOrder[0] = currentOrder[1];
        currentOrder[1] = temp;
      }
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  void _onPieceDropped(int sourceIndex, int targetIndex) {
    if (!isPlaying) return;

    setState(() {
      int temp = currentOrder[sourceIndex];
      currentOrder[sourceIndex] = currentOrder[targetIndex];
      currentOrder[targetIndex] = temp;
      moves++;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    bool hasWon = true;
    for (int i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i] != correctOrder[i]) {
        hasWon = false;
        break;
      }
    }

    if (hasWon) {
      timer?.cancel();
      setState(() {
        isPlaying = false;
      });
      _showWinDialog();
    }
  }

  int _calculateScore() {
    int baseScore = widget.gridSize * widget.gridSize * 100;
    int timePenalty = seconds * 2;
    int movePenalty = (moves - (widget.gridSize * widget.gridSize)) * 5;
    int finalScore = baseScore - timePenalty - (movePenalty > 0 ? movePenalty : 0);
    return finalScore > 0 ? finalScore : 0;
  }

  void _showWinDialog() {
    final int score = _calculateScore();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            'Puzzle Completed! 🎉',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Final Score', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    '$score',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Time', _formatTime(seconds), Icons.timer),
                _buildStat('Moves', '$moves', Icons.swap_horiz),
                _buildStat('Size', '${widget.gridSize}x${widget.gridSize}', Icons.grid_on),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to game selection
            },
            child: const Text('Change Settings', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _initializeBoard();
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jigsaw Puzzle'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Time: ${_formatTime(seconds)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Moves: $moves', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double pieceWidth = constraints.maxWidth / widget.gridSize;
                        double pieceHeight = constraints.maxHeight / widget.gridSize;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: widget.gridSize,
                          ),
                          itemCount: widget.gridSize * widget.gridSize,
                          itemBuilder: (context, index) {
                            int originalIndex = currentOrder[index];
                            bool isCorrect = originalIndex == index;

                            Widget pieceWidget = PuzzlePiece(
                              imageUrl: widget.imageUrl,
                              gridSize: widget.gridSize,
                              index: originalIndex,
                              pieceWidth: pieceWidth,
                              pieceHeight: pieceHeight,
                            );

                            return DragTarget<int>(
                              onAccept: (sourceIndex) {
                                _onPieceDropped(sourceIndex, index);
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Draggable<int>(
                                  data: index, // Passing current slot index
                                  feedback: Material(
                                    elevation: 8,
                                    child: Opacity(
                                      opacity: 0.8,
                                      child: SizedBox(
                                        width: pieceWidth,
                                        height: pieceHeight,
                                        child: pieceWidget,
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Container(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: pieceWidget,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: isPlaying ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(isPlaying ? 'Playing...' : 'Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PuzzlePiece extends StatelessWidget {
  final String imageUrl;
  final int gridSize;
  final int index;
  final double pieceWidth;
  final double pieceHeight;

  const PuzzlePiece({
    Key? key,
    required this.imageUrl,
    required this.gridSize,
    required this.index,
    required this.pieceWidth,
    required this.pieceHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int row = index ~/ gridSize;
    int col = index % gridSize;

    return ClipRect(
      child: SizedBox(
        width: pieceWidth,
        height: pieceHeight,
        child: Stack(
          children: [
            Positioned(
              left: -col * pieceWidth,
              top: -row * pieceHeight,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: pieceWidth * gridSize,
                height: pieceHeight * gridSize,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: pieceWidth,
                    height: pieceHeight,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: pieceWidth,
                  height: pieceHeight,
                  child: const Center(child: Icon(Icons.error, size: 24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
