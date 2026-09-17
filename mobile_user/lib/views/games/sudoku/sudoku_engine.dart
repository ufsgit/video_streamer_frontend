import 'dart:math';

enum SudokuDifficulty {
  easy(
    name: 'Easy',
    dimension: 4,
    boxRows: 2,
    boxCols: 2,
    clueCount: 8,
    description: '4x4 Grid (Numbers 1-4)',
  ),
  medium(
    name: 'Medium',
    dimension: 6,
    boxRows: 2,
    boxCols: 3,
    clueCount: 16,
    description: '6x6 Grid (Numbers 1-6)',
  ),
  hard(
    name: 'Hard',
    dimension: 9,
    boxRows: 3,
    boxCols: 3,
    clueCount: 32,
    description: '9x9 Grid (Numbers 1-9)',
  );

  final String name;
  final int dimension;
  final int boxRows;
  final int boxCols;
  final int clueCount;
  final String description;

  const SudokuDifficulty({
    required this.name,
    required this.dimension,
    required this.boxRows,
    required this.boxCols,
    required this.clueCount,
    required this.description,
  });
}

class SudokuCell {
  final int row;
  final int col;
  final int solutionValue;
  final bool isClue;
  int currentValue;
  Set<int> notes;
  bool isError;

  SudokuCell({
    required this.row,
    required this.col,
    required this.solutionValue,
    required this.isClue,
    this.currentValue = 0,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? <int>{};

  SudokuCell copyWith({
    int? currentValue,
    Set<int>? notes,
    bool? isError,
  }) {
    return SudokuCell(
      row: row,
      col: col,
      solutionValue: solutionValue,
      isClue: isClue,
      currentValue: currentValue ?? this.currentValue,
      notes: notes ?? Set<int>.from(this.notes),
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'solutionValue': solutionValue,
      'isClue': isClue,
      'currentValue': currentValue,
      'notes': notes.toList(),
      'isError': isError,
    };
  }

  factory SudokuCell.fromJson(Map<String, dynamic> json) {
    return SudokuCell(
      row: json['row'] as int,
      col: json['col'] as int,
      solutionValue: json['solutionValue'] as int,
      isClue: json['isClue'] as bool,
      currentValue: json['currentValue'] as int? ?? 0,
      notes: (json['notes'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toSet() ?? <int>{},
      isError: json['isError'] as bool? ?? false,
    );
  }
}

class SudokuPuzzle {
  final SudokuDifficulty difficulty;
  final List<List<SudokuCell>> grid;

  SudokuPuzzle({
    required this.difficulty,
    required this.grid,
  });

  int get dimension => difficulty.dimension;
  int get boxRows => difficulty.boxRows;
  int get boxCols => difficulty.boxCols;

  bool isComplete() {
    for (int r = 0; r < dimension; r++) {
      for (int c = 0; c < dimension; c++) {
        final cell = grid[r][c];
        if (cell.currentValue == 0 || cell.currentValue != cell.solutionValue) {
          return false;
        }
      }
    }
    return true;
  }

  int countNumberOccurrences(int number) {
    int count = 0;
    for (int r = 0; r < dimension; r++) {
      for (int c = 0; c < dimension; c++) {
        if (grid[r][c].currentValue == number) {
          count++;
        }
      }
    }
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty.name,
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    };
  }

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    final diffName = json['difficulty'] as String? ?? 'Easy';
    final diff = SudokuDifficulty.values.firstWhere(
      (d) => d.name.toLowerCase() == diffName.toLowerCase(),
      orElse: () => SudokuDifficulty.easy,
    );
    final rawGrid = json['grid'] as List<dynamic>;
    final cells = rawGrid.map((rawRow) {
      return (rawRow as List<dynamic>).map((rawCell) {
        return SudokuCell.fromJson(rawCell as Map<String, dynamic>);
      }).toList();
    }).toList();

    return SudokuPuzzle(difficulty: diff, grid: cells);
  }
}

class SudokuGenerator {
  final Random _random = Random();

  SudokuPuzzle generate(SudokuDifficulty difficulty) {
    final dim = difficulty.dimension;
    final boxR = difficulty.boxRows;
    final boxC = difficulty.boxCols;

    // 1. Generate fully solved valid grid
    final solution = List.generate(dim, (_) => List.filled(dim, 0));
    _fillGrid(solution, dim, boxR, boxC);

    // 2. Create puzzle by removing cells according to target clue count
    final puzzleGrid = List.generate(dim, (r) => List<int>.from(solution[r]));
    final totalCells = dim * dim;
    final cellsToRemove = totalCells - difficulty.clueCount;

    final cellIndices = List.generate(totalCells, (i) => i)..shuffle(_random);
    int removed = 0;

    for (final index in cellIndices) {
      if (removed >= cellsToRemove) break;
      final r = index ~/ dim;
      final c = index % dim;

      final temp = puzzleGrid[r][c];
      puzzleGrid[r][c] = 0;

      // Verify unique solution
      if (_countSolutions(puzzleGrid, dim, boxR, boxC) == 1) {
        removed++;
      } else {
        puzzleGrid[r][c] = temp; // Restore if multiple solutions
      }
    }

    // 3. Build SudokuCell matrix
    final cells = List.generate(dim, (r) {
      return List.generate(dim, (c) {
        final val = puzzleGrid[r][c];
        final isClue = val != 0;
        return SudokuCell(
          row: r,
          col: c,
          solutionValue: solution[r][c],
          isClue: isClue,
          currentValue: val,
        );
      });
    });

    return SudokuPuzzle(difficulty: difficulty, grid: cells);
  }

  bool _fillGrid(List<List<int>> grid, int dim, int boxR, int boxC) {
    for (int r = 0; r < dim; r++) {
      for (int c = 0; c < dim; c++) {
        if (grid[r][c] == 0) {
          final numbers = List.generate(dim, (i) => i + 1)..shuffle(_random);
          for (final num in numbers) {
            if (_isValidPlacement(grid, r, c, num, dim, boxR, boxC)) {
              grid[r][c] = num;
              if (_fillGrid(grid, dim, boxR, boxC)) {
                return true;
              }
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(
    List<List<int>> grid,
    int row,
    int col,
    int num,
    int dim,
    int boxR,
    int boxC,
  ) {
    // Check row
    for (int c = 0; c < dim; c++) {
      if (grid[row][c] == num) return false;
    }

    // Check col
    for (int r = 0; r < dim; r++) {
      if (grid[r][col] == num) return false;
    }

    // Check subgrid box
    final startR = (row ~/ boxR) * boxR;
    final startC = (col ~/ boxC) * boxC;

    for (int r = 0; r < boxR; r++) {
      for (int c = 0; c < boxC; c++) {
        if (grid[startR + r][startC + c] == num) return false;
      }
    }

    return true;
  }

  int _countSolutions(
    List<List<int>> grid,
    int dim,
    int boxR,
    int boxC, {
    int count = 0,
  }) {
    for (int r = 0; r < dim; r++) {
      for (int c = 0; c < dim; c++) {
        if (grid[r][c] == 0) {
          for (int num = 1; num <= dim; num++) {
            if (_isValidPlacement(grid, r, c, num, dim, boxR, boxC)) {
              grid[r][c] = num;
              count = _countSolutions(grid, dim, boxR, boxC, count: count);
              grid[r][c] = 0;
              if (count >= 2) return count; // Short circuit
            }
          }
          return count;
        }
      }
    }
    return count + 1;
  }
}
