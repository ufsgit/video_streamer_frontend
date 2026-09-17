import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sudoku_engine.dart';

class SudokuMove {
  final int row;
  final int col;
  final int previousValue;
  final int newValue;
  final Set<int> previousNotes;
  final Set<int> newNotes;

  SudokuMove({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.newValue,
    required this.previousNotes,
    required this.newNotes,
  });
}

class SudokuGameView extends StatefulWidget {
  final SudokuDifficulty initialDifficulty;

  const SudokuGameView({
    super.key,
    this.initialDifficulty = SudokuDifficulty.easy,
  });

  @override
  State<SudokuGameView> createState() => _SudokuGameViewState();
}

class _SudokuGameViewState extends State<SudokuGameView>
    with WidgetsBindingObserver {
  final SudokuGenerator _generator = SudokuGenerator();
  late SudokuDifficulty _currentDifficulty;
  late SudokuPuzzle _puzzle;

  int? _selectedRow;
  int? _selectedCol;
  bool _isNotesMode = false;
  int _mistakes = 0;

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isGameCompleted = false;

  final List<SudokuMove> _moveHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDifficulty = widget.initialDifficulty;
    _puzzle = _generator.generate(_currentDifficulty);
    _loadOrStartGame(_currentDifficulty);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (!_isGameCompleted) {
      _saveGameState();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _timer?.cancel();
      if (!_isGameCompleted) {
        _saveGameState();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isGameCompleted && (_timer == null || !_timer!.isActive)) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameCompleted && mounted) {
        setState(() {
          _secondsElapsed++;
        });
        if (_secondsElapsed % 5 == 0) {
          _saveGameState();
        }
      }
    });
  }

  Future<void> _loadOrStartGame(SudokuDifficulty difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('sudoku_saved_${difficulty.name.toLowerCase()}');
      if (savedJson != null && savedJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(savedJson);
        final bool isCompleted = data['isCompleted'] as bool? ?? false;
        if (!isCompleted && data['puzzle'] != null) {
          final restoredPuzzle = SudokuPuzzle.fromJson(data['puzzle'] as Map<String, dynamic>);
          if (mounted) {
            setState(() {
              _currentDifficulty = difficulty;
              _puzzle = restoredPuzzle;
              _secondsElapsed = data['secondsElapsed'] as int? ?? 0;
              _mistakes = data['mistakes'] as int? ?? 0;
              _isGameCompleted = false;
              _selectedRow = null;
              _selectedCol = null;
              _moveHistory.clear();
              _isNotesMode = false;
            });
            _startTimer();
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: start a fresh game if no valid saved state
    _startNewGame(difficulty, forceFresh: false);
  }

  Future<void> _saveGameState() async {
    if (_isGameCompleted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'puzzle': _puzzle.toJson(),
        'secondsElapsed': _secondsElapsed,
        'mistakes': _mistakes,
        'isCompleted': _isGameCompleted,
      };
      await prefs.setString(
        'sudoku_saved_${_currentDifficulty.name.toLowerCase()}',
        jsonEncode(data),
      );
    } catch (_) {}
  }

  Future<void> _clearSavedGame(SudokuDifficulty difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sudoku_saved_${difficulty.name.toLowerCase()}');
    } catch (_) {}
  }

  void _startNewGame(SudokuDifficulty difficulty, {bool forceFresh = true}) {
    if (forceFresh) {
      _clearSavedGame(difficulty);
    }
    setState(() {
      _currentDifficulty = difficulty;
      _puzzle = _generator.generate(difficulty);
      _selectedRow = null;
      _selectedCol = null;
      _mistakes = 0;
      _secondsElapsed = 0;
      _isGameCompleted = false;
      _moveHistory.clear();
      _isNotesMode = false;
    });
    _startTimer();
    _saveGameState();
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _onCellTapped(int row, int col) {
    if (_isGameCompleted) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberInput(int number) {
    if (_isGameCompleted || _selectedRow == null || _selectedCol == null) {
      return;
    }

    final cell = _puzzle.grid[_selectedRow!][_selectedCol!];
    if (cell.isClue) return;

    if (_isNotesMode) {
      // Toggle note
      setState(() {
        final prevNotes = Set<int>.from(cell.notes);
        final newNotes = Set<int>.from(cell.notes);
        if (newNotes.contains(number)) {
          newNotes.remove(number);
        } else {
          newNotes.add(number);
        }
        cell.notes = newNotes;
        _moveHistory.add(
          SudokuMove(
            row: _selectedRow!,
            col: _selectedCol!,
            previousValue: cell.currentValue,
            newValue: cell.currentValue,
            previousNotes: prevNotes,
            newNotes: newNotes,
          ),
        );
      });
      return;
    }

    // Direct number entry
    if (cell.currentValue == number) {
      // Already same number
      return;
    }

    final prevValue = cell.currentValue;
    final prevNotes = Set<int>.from(cell.notes);
    final isCorrect = number == cell.solutionValue;

    setState(() {
      cell.currentValue = number;
      cell.notes.clear();

      if (!isCorrect) {
        cell.isError = true;
        _mistakes++;
      } else {
        cell.isError = false;
        // Clean up notes in same row, col, and subgrid
        _cleanNotesForNumber(_selectedRow!, _selectedCol!, number);

        if (_puzzle.isComplete()) {
          _handleGameComplete();
        }
      }

      _moveHistory.add(
        SudokuMove(
          row: _selectedRow!,
          col: _selectedCol!,
          previousValue: prevValue,
          newValue: number,
          previousNotes: prevNotes,
          newNotes: const {},
        ),
      );
    });
    _saveGameState();
  }

  void _cleanNotesForNumber(int row, int col, int number) {
    final dim = _puzzle.dimension;
    final boxR = _puzzle.boxRows;
    final boxC = _puzzle.boxCols;

    for (int c = 0; c < dim; c++) {
      _puzzle.grid[row][c].notes.remove(number);
    }
    for (int r = 0; r < dim; r++) {
      _puzzle.grid[r][col].notes.remove(number);
    }
    final startR = (row ~/ boxR) * boxR;
    final startC = (col ~/ boxC) * boxC;
    for (int r = 0; r < boxR; r++) {
      for (int c = 0; c < boxC; c++) {
        _puzzle.grid[startR + r][startC + c].notes.remove(number);
      }
    }
  }

  void _onErase() {
    if (_isGameCompleted || _selectedRow == null || _selectedCol == null) {
      return;
    }
    final cell = _puzzle.grid[_selectedRow!][_selectedCol!];
    if (cell.isClue) return;

    if (cell.currentValue != 0 || cell.notes.isNotEmpty) {
      setState(() {
        _moveHistory.add(
          SudokuMove(
            row: _selectedRow!,
            col: _selectedCol!,
            previousValue: cell.currentValue,
            newValue: 0,
            previousNotes: Set<int>.from(cell.notes),
            newNotes: const {},
          ),
        );
        cell.currentValue = 0;
        cell.notes.clear();
        cell.isError = false;
      });
      _saveGameState();
    }
  }

  void _onUndo() {
    if (_isGameCompleted || _moveHistory.isEmpty) return;
    setState(() {
      final lastMove = _moveHistory.removeLast();
      final cell = _puzzle.grid[lastMove.row][lastMove.col];
      cell.currentValue = lastMove.previousValue;
      cell.notes = Set<int>.from(lastMove.previousNotes);
      cell.isError =
          cell.currentValue != 0 && cell.currentValue != cell.solutionValue;
      _selectedRow = lastMove.row;
      _selectedCol = lastMove.col;
    });
    _saveGameState();
  }

  void _onHint() {
    if (_isGameCompleted) return;
    // If a cell is selected and empty, reveal it
    if (_selectedRow != null && _selectedCol != null) {
      final cell = _puzzle.grid[_selectedRow!][_selectedCol!];
      if (!cell.isClue && cell.currentValue != cell.solutionValue) {
        setState(() {
          cell.currentValue = cell.solutionValue;
          cell.notes.clear();
          cell.isError = false;
          _cleanNotesForNumber(
            _selectedRow!,
            _selectedCol!,
            cell.solutionValue,
          );
          if (_puzzle.isComplete()) {
            _handleGameComplete();
          }
        });
        _saveGameState();
        return;
      }
    }

    // Otherwise find the first empty cell and reveal it
    for (int r = 0; r < _puzzle.dimension; r++) {
      for (int c = 0; c < _puzzle.dimension; c++) {
        final cell = _puzzle.grid[r][c];
        if (cell.currentValue == 0 || cell.currentValue != cell.solutionValue) {
          setState(() {
            _selectedRow = r;
            _selectedCol = c;
            cell.currentValue = cell.solutionValue;
            cell.notes.clear();
            cell.isError = false;
            _cleanNotesForNumber(r, c, cell.solutionValue);
            if (_puzzle.isComplete()) {
              _handleGameComplete();
            }
          });
          _saveGameState();
          return;
        }
      }
    }
  }

  void _handleGameComplete() {
    _isGameCompleted = true;
    _timer?.cancel();
    _clearSavedGame(_currentDifficulty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Puzzle Solved!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Difficulty: ${_currentDifficulty.name} (${_currentDifficulty.description})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_secondsElapsed),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFCBD5E1),
                      ),
                      Column(
                        children: [
                          const Text(
                            'Mistakes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_mistakes',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
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
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
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
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          // Cycle to next difficulty or restart
                          final nextIndex =
                              (_currentDifficulty.index + 1) %
                              SudokuDifficulty.values.length;
                          _startNewGame(SudokuDifficulty.values[nextIndex]);
                        },
                        child: const Text(
                          'Next Level',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: const Text(
          'Sudoku',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: () => _startNewGame(_currentDifficulty, forceFresh: true),
            tooltip: 'Restart',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Difficulty segmented control
              _buildDifficultySelector(),

              const SizedBox(height: 14),

              // 2. Stats bar (Mistakes, Timer, Difficulty)
              _buildStatsBar(),

              const SizedBox(height: 16),

              // 3. Sudoku Grid Board
              _buildSudokuBoard(),

              const SizedBox(height: 16),

              // 4. Action buttons (Undo, Erase, Notes, Hint)
              _buildActionToolbar(),

              const SizedBox(height: 14),

              // 5. Keypad numbers (1-4, 1-6, or 1-9)
              _buildNumberKeypad(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: SudokuDifficulty.values.map((diff) {
          final isSelected = diff == _currentDifficulty;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (diff != _currentDifficulty) {
                  _saveGameState();
                  _loadOrStartGame(diff);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${diff.name} (${diff.dimension}x${diff.dimension})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6366F1)),
          const SizedBox(width: 6),
          Text(
            _formatTime(_secondsElapsed),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuBoard() {
    final dim = _puzzle.dimension;
    final boxR = _puzzle.boxRows;
    final boxC = _puzzle.boxCols;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max square size
        final boardSize = constraints.maxWidth > 420
            ? 400.0
            : constraints.maxWidth;

        final selectedNumber = (_selectedRow != null && _selectedCol != null)
            ? _puzzle.grid[_selectedRow!][_selectedCol!].currentValue
            : 0;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B), width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: List.generate(dim, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(dim, (col) {
                        final cell = _puzzle.grid[row][col];
                        final isSelected =
                            row == _selectedRow && col == _selectedCol;
                        final isSameRowOrColOrBox =
                            _selectedRow != null &&
                            _selectedCol != null &&
                            (row == _selectedRow ||
                                col == _selectedCol ||
                                ((row ~/ boxR) == (_selectedRow! ~/ boxR) &&
                                    (col ~/ boxC) == (_selectedCol! ~/ boxC)));

                        final isSameNumber =
                            selectedNumber != 0 &&
                            cell.currentValue != 0 &&
                            cell.currentValue == selectedNumber;

                        // Determine borders for boxes
                        final isBoxBottom =
                            (row + 1) % boxR == 0 && row < dim - 1;
                        final isBoxRight =
                            (col + 1) % boxC == 0 && col < dim - 1;

                        Color cellBgColor = Colors.white;
                        if (isSelected) {
                          cellBgColor = const Color(0xFFC7D2FE);
                        } else if (isSameNumber) {
                          cellBgColor = const Color(0xFFE0E7FF);
                        } else if (isSameRowOrColOrBox) {
                          cellBgColor = const Color(0xFFF1F5F9);
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onCellTapped(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellBgColor,
                                border: Border(
                                  right: BorderSide(
                                    color: isBoxRight
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFCBD5E1),
                                    width: isBoxRight ? 2.0 : 0.8,
                                  ),
                                  bottom: BorderSide(
                                    color: isBoxBottom
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFCBD5E1),
                                    width: isBoxBottom ? 2.0 : 0.8,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: _buildCellContent(cell, dim),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCellContent(SudokuCell cell, int dim) {
    if (cell.currentValue != 0) {
      final isClue = cell.isClue;
      return Text(
        '${cell.currentValue}',
        style: TextStyle(
          fontSize: dim == 4 ? 26 : (dim == 6 ? 22 : 18),
          fontWeight: isClue ? FontWeight.w900 : FontWeight.w700,
          color: isClue ? const Color(0xFF0F172A) : const Color(0xFF4F46E5),
        ),
      );
    }

    // Notes mode display
    if (cell.notes.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 1,
          children: cell.notes.map((n) {
            return Text(
              '$n',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            );
          }).toList(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          onTap: _onUndo,
        ),
        _buildActionButton(
          icon: Icons.backspace_outlined,
          label: 'Erase',
          onTap: _onErase,
        ),
        _buildActionButton(
          icon: Icons.edit_note_rounded,
          label: 'Notes',
          isActive: _isNotesMode,
          onTap: () {
            setState(() {
              _isNotesMode = !_isNotesMode;
            });
          },
        ),
        _buildActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          onTap: _onHint,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberKeypad() {
    final dim = _puzzle.dimension;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(dim, (index) {
          final number = index + 1;
          final completed = _puzzle.countNumberOccurrences(number) >= dim;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: completed ? null : () => _onNumberInput(number),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: completed
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: completed
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFC7D2FE),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: dim <= 6 ? 22 : 18,
                          fontWeight: FontWeight.w800,
                          color: completed
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
