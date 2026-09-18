import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class JigsawPuzzleView extends StatefulWidget {
  final String imageUrl;
  final int gridSize;

  const JigsawPuzzleView({
    super.key,
    this.imageUrl =
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000&auto=format&fit=crop',
    this.gridSize = 3,
  });

  @override
  State<JigsawPuzzleView> createState() => _JigsawPuzzleViewState();
}

class _JigsawPuzzleViewState extends State<JigsawPuzzleView> {
  late List<int> currentOrder;
  late List<int> correctOrder;
  bool isPlaying = false;
  int moves = 0;
  int seconds = 0;
  Timer? timer;
  bool showNumbers = false;
  bool showReferencePreview = false;
  bool isFullscreen = true;

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
    final int totalPieces = widget.gridSize * widget.gridSize;
    correctOrder = List.generate(totalPieces, (index) => index);
    currentOrder = List.from(correctOrder);
    moves = 0;
    seconds = 0;
    isPlaying = false;
    timer?.cancel();
    setState(() {});
  }

  void _startGame() {
    final int totalPieces = widget.gridSize * widget.gridSize;
    setState(() {
      isPlaying = true;
      moves = 0;
      seconds = 0;
      currentOrder = List.generate(totalPieces, (i) => i)..shuffle(Random());

      // Ensure not solved by accident
      bool isSolved = true;
      for (int i = 0; i < currentOrder.length; i++) {
        if (currentOrder[i] != correctOrder[i]) {
          isSolved = false;
          break;
        }
      }
      if (isSolved && currentOrder.length > 1) {
        final temp = currentOrder[0];
        currentOrder[0] = currentOrder[1];
        currentOrder[1] = temp;
      }
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          seconds++;
        });
      }
    });
  }

  void _onPieceDropped(int sourceIndex, int targetIndex) {
    if (!isPlaying || sourceIndex == targetIndex) return;

    setState(() {
      final temp = currentOrder[sourceIndex];
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
    final int total = widget.gridSize * widget.gridSize;
    final int baseScore = total * 120;
    final int timePenalty = seconds * 2;
    final int movePenalty = (moves - total) * 4;
    final int finalScore =
        baseScore - timePenalty - (movePenalty > 0 ? movePenalty : 0);
    return finalScore > 0 ? finalScore : 50;
  }

  void _showWinDialog() {
    final int score = _calculateScore();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Puzzle Completed! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.gridSize}x${widget.gridSize} Grid Assembled',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWinStat('Score', '$score', Icons.stars_rounded),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFCBD5E1),
                    ),
                    _buildWinStat('Time', _formatTime(seconds), Icons.timer_outlined),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFCBD5E1),
                    ),
                    _buildWinStat('Moves', '$moves', Icons.swap_horiz_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _initializeBoard();
                        _startGame();
                      },
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildWinStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showImagePreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton.filled(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark sleek immersive background
      body: SafeArea(
        child: Stack(
          children: [
            // Main Fullscreen Content
            Column(
              children: [
                // Top Overlay Controls Bar
                _buildTopBar(),

                // Center Fullscreen Puzzle Board
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Maximize square size across viewport
                        final double size = min(
                          constraints.maxWidth - 16,
                          constraints.maxHeight - 16,
                        );

                        final double pieceSize = size / widget.gridSize;

                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF38BDF8),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.gridSize,
                              ),
                              itemCount: widget.gridSize * widget.gridSize,
                              itemBuilder: (context, index) {
                                final int originalIndex = currentOrder[index];
                                final bool isCorrect = originalIndex == index;

                                final Widget pieceWidget = PuzzlePiece(
                                  imageUrl: widget.imageUrl,
                                  gridSize: widget.gridSize,
                                  index: originalIndex,
                                  pieceWidth: pieceSize,
                                  pieceHeight: pieceSize,
                                  showNumber: showNumbers,
                                );

                                return DragTarget<int>(
                                  onWillAcceptWithDetails: (details) => true,
                                  onAcceptWithDetails: (details) {
                                    _onPieceDropped(details.data, index);
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) {
                                    final isHovered = candidateData.isNotEmpty;

                                    return Draggable<int>(
                                      data: index,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        elevation: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFF38BDF8),
                                              width: 2,
                                            ),
                                          ),
                                          width: pieceSize,
                                          height: pieceSize,
                                          child: pieceWidget,
                                        ),
                                      ),
                                      childWhenDragging: Container(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isHovered
                                                ? const Color(0xFF38BDF8)
                                                : (isCorrect
                                                    ? const Color(0xFF10B981)
                                                        .withValues(alpha: 0.5)
                                                    : Colors.white
                                                        .withValues(alpha: 0.18)),
                                            width: isHovered ? 2.0 : 0.6,
                                          ),
                                        ),
                                        child: pieceWidget,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      // Numbers hint toggle
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: showNumbers
                              ? const Color(0xFF0D9488)
                              : Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.numbers_rounded, size: 22),
                        tooltip: 'Toggle Number Guides',
                        onPressed: () {
                          setState(() {
                            showNumbers = !showNumbers;
                          });
                        },
                      ),
                      const SizedBox(width: 12),

                      // Peek reference image
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 22),
                        tooltip: 'Preview Full Picture',
                        onPressed: _showImagePreviewDialog,
                      ),
                      const SizedBox(width: 12),

                      // Play / Restart Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isPlaying
                                ? () {
                                    _initializeBoard();
                                    _startGame();
                                  }
                                : _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Icon(
                              isPlaying
                                  ? Icons.shuffle_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                            ),
                            label: Text(
                              isPlaying ? 'Shuffle / Restart' : 'Start Game',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Exit',
          ),

          // Live stats chips
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(seconds),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: Color(0xFF34D399),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$moves Moves',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Grid size badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0D9488)),
            ),
            child: Text(
              '${widget.gridSize}x${widget.gridSize}',
              style: const TextStyle(
                color: Color(0xFF2DD4BF),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
  final bool showNumber;

  const PuzzlePiece({
    super.key,
    required this.imageUrl,
    required this.gridSize,
    required this.index,
    required this.pieceWidth,
    required this.pieceHeight,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final int row = index ~/ gridSize;
    final int col = index % gridSize;

    final double totalGridWidth = pieceWidth * gridSize;
    final double totalGridHeight = pieceHeight * gridSize;

    return ClipRect(
      child: SizedBox(
        width: pieceWidth,
        height: pieceHeight,
        child: Stack(
          children: [
            // 100% full image mapped across all pieces without cropping
            Positioned(
              left: -col * pieceWidth,
              top: -row * pieceHeight,
              child: Image.network(
                imageUrl,
                fit: BoxFit.fill,
                width: totalGridWidth,
                height: totalGridHeight,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: totalGridWidth,
                    height: totalGridHeight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: totalGridWidth,
                  height: totalGridHeight,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 24, color: Colors.white54),
                  ),
                ),
              ),
            ),

            // Number overlay guide (optional helper)
            if (showNumber)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
