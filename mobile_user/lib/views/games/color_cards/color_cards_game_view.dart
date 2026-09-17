import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameColorCard {
  final int id;
  final String name;
  final Color color;
  final Color darkColor;
  final IconData icon;

  const GameColorCard({
    required this.id,
    required this.name,
    required this.color,
    required this.darkColor,
    required this.icon,
  });
}

const List<GameColorCard> kCardColorPalette = [
  GameColorCard(
    id: 1,
    name: 'Ruby Red',
    color: Color(0xFFEF4444),
    darkColor: Color(0xFFB91C1C),
    icon: Icons.favorite_rounded,
  ),
  GameColorCard(
    id: 2,
    name: 'Ocean Blue',
    color: Color(0xFF3B82F6),
    darkColor: Color(0xFF1D4ED8),
    icon: Icons.water_drop_rounded,
  ),
  GameColorCard(
    id: 3,
    name: 'Emerald Green',
    color: Color(0xFF10B981),
    darkColor: Color(0xFF047857),
    icon: Icons.eco_rounded,
  ),
  GameColorCard(
    id: 4,
    name: 'Amber Gold',
    color: Color(0xFFF59E0B),
    darkColor: Color(0xFFB45309),
    icon: Icons.wb_sunny_rounded,
  ),
  GameColorCard(
    id: 5,
    name: 'Royal Purple',
    color: Color(0xFF8B5CF6),
    darkColor: Color(0xFF6D28D9),
    icon: Icons.auto_awesome_rounded,
  ),
  GameColorCard(
    id: 6,
    name: 'Rose Pink',
    color: Color(0xFFEC4899),
    darkColor: Color(0xFFBE185D),
    icon: Icons.local_florist_rounded,
  ),
  GameColorCard(
    id: 7,
    name: 'Teal Cyan',
    color: Color(0xFF06B6D4),
    darkColor: Color(0xFF0E7490),
    icon: Icons.diamond_rounded,
  ),
  GameColorCard(
    id: 8,
    name: 'Coral Orange',
    color: Color(0xFFF97316),
    darkColor: Color(0xFFC2410C),
    icon: Icons.local_fire_department_rounded,
  ),
  GameColorCard(
    id: 9,
    name: 'Electric Indigo',
    color: Color(0xFF6366F1),
    darkColor: Color(0xFF4338CA),
    icon: Icons.bolt_rounded,
  ),
  GameColorCard(
    id: 10,
    name: 'Lime Green',
    color: Color(0xFF84CC16),
    darkColor: Color(0xFF4D7C0F),
    icon: Icons.park_rounded,
  ),
  GameColorCard(
    id: 11,
    name: 'Sunset Maroon',
    color: Color(0xFFE11D48),
    darkColor: Color(0xFF9F1239),
    icon: Icons.star_rounded,
  ),
  GameColorCard(
    id: 12,
    name: 'Sky Azure',
    color: Color(0xFF0EA5E9),
    darkColor: Color(0xFF0369A1),
    icon: Icons.cloud_rounded,
  ),
  GameColorCard(
    id: 13,
    name: 'Deep Violet',
    color: Color(0xFFA855F7),
    darkColor: Color(0xFF7E22CE),
    icon: Icons.brightness_auto_rounded,
  ),
  GameColorCard(
    id: 14,
    name: 'Warm Amber',
    color: Color(0xFFD97706),
    darkColor: Color(0xFF92400E),
    icon: Icons.emoji_events_rounded,
  ),
  GameColorCard(
    id: 15,
    name: 'Mint Teal',
    color: Color(0xFF14B8A6),
    darkColor: Color(0xFF0F766E),
    icon: Icons.spa_rounded,
  ),
];

enum GamePhase {
  memorize,
  arrange,
  roundResult,
}

class ColorCardsGameView extends StatefulWidget {
  final int initialCardCount;

  const ColorCardsGameView({
    super.key,
    this.initialCardCount = 5,
  });

  @override
  State<ColorCardsGameView> createState() => _ColorCardsGameViewState();
}

class _ColorCardsGameViewState extends State<ColorCardsGameView>
    with WidgetsBindingObserver {
  late int _cardCount;
  int _highestLevel = 5;
  int _roundScore = 0;

  GamePhase _phase = GamePhase.memorize;
  List<GameColorCard> _targetSequence = [];
  List<GameColorCard> _userSequence = [];
  List<GameColorCard?> _userPlacedSlots = [];

  Timer? _countdownTimer;
  int _memorizeSecondsLeft = 5;
  int _totalMemorizeSeconds = 5;

  Timer? _sessionTimer;
  int _totalSecondsElapsed = 0;

  bool _isSuccessRound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cardCount = widget.initialCardCount.clamp(3, 6);
    _loadSavedLevel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _saveLevel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _sessionTimer?.cancel();
      _saveLevel();
    } else if (state == AppLifecycleState.resumed) {
      _startSessionTimer();
    }
  }

  Future<void> _loadSavedLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHighest = prefs.getInt('color_cards_highest_level') ?? 5;

      if (mounted) {
        setState(() {
          _highestLevel = savedHighest;
          _cardCount = widget.initialCardCount.clamp(3, 6);
        });
      }
    } catch (_) {}

    _startNewRound();
    _startSessionTimer();
  }

  Future<void> _saveLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('color_cards_saved_level', _cardCount);
      if (_cardCount > _highestLevel) {
        _highestLevel = _cardCount;
        await prefs.setInt('color_cards_highest_level', _highestLevel);
      }
    } catch (_) {}
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _totalSecondsElapsed++;
        });
      }
    });
  }

  void _startNewRound() {
    _countdownTimer?.cancel();

    // Select N distinct colors
    final shuffledPalette = List<GameColorCard>.from(kCardColorPalette)
      ..shuffle(Random());
    final selectedColors = shuffledPalette.take(_cardCount).toList();

    _targetSequence = List<GameColorCard>.from(selectedColors);

    // Scramble for user deck
    _userSequence = List<GameColorCard>.from(selectedColors)..shuffle(Random());
    _userPlacedSlots = List<GameColorCard?>.filled(_cardCount, null);

    // Dynamic timer: e.g. 5 cards = 5s, 7 cards = 7s, 9 cards = 9s
    _totalMemorizeSeconds = max(4, _cardCount);
    _memorizeSecondsLeft = _totalMemorizeSeconds;
    _phase = GamePhase.memorize;
    _isSuccessRound = false;

    _saveLevel();

    if (mounted) setState(() {});

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_memorizeSecondsLeft > 1) {
          _memorizeSecondsLeft--;
        } else {
          _startArrangePhase();
        }
      });
    });
  }

  void _startArrangePhase() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = GamePhase.arrange;
    });
  }

  void _onCardTappedToPlace(GameColorCard card) {
    if (_phase != GamePhase.arrange) return;

    // Find first empty slot
    final emptyIndex = _userPlacedSlots.indexOf(null);
    if (emptyIndex != -1) {
      setState(() {
        _userPlacedSlots[emptyIndex] = card;
        _userSequence.remove(card);
      });
      _checkCompletion();
    }
  }

  void _onSlotTappedToReturn(int index) {
    if (_phase != GamePhase.arrange) return;
    final card = _userPlacedSlots[index];
    if (card != null) {
      setState(() {
        _userPlacedSlots[index] = null;
        _userSequence.add(card);
      });
    }
  }

  void _onResetPlacedSlots() {
    if (_phase != GamePhase.arrange) return;
    setState(() {
      for (final card in _userPlacedSlots) {
        if (card != null) {
          _userSequence.add(card);
        }
      }
      _userPlacedSlots = List<GameColorCard?>.filled(_cardCount, null);
    });
  }

  void _checkCompletion() {
    if (_userPlacedSlots.contains(null)) {
      return; // Still filling slots
    }

    // All slots filled, verify sequence
    bool isCorrect = true;
    for (int i = 0; i < _cardCount; i++) {
      if (_userPlacedSlots[i]?.id != _targetSequence[i].id) {
        isCorrect = false;
        break;
      }
    }

    setState(() {
      _phase = GamePhase.roundResult;
      _isSuccessRound = isCorrect;
      if (isCorrect) {
        _roundScore += (_cardCount * 100);
      }
    });
  }

  void _onNextRound() {
    // Progress to next round: card count increases by 2
    setState(() {
      _cardCount += 2;
    });
    _startNewRound();
  }

  void _onRetryRound() {
    _startNewRound();
  }

  void _showCardCountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Starting Cards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose starting card count under 7:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [3, 4, 5, 6].map((count) {
                  final isSelected = _cardCount == count;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _cardCount = count;
                      });
                      _startNewRound();
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEA580C)
                              : const Color(0xFFCBD5E1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
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
          'Colour Cards',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF475569)),
            onPressed: _showCardCountPicker,
            tooltip: 'Select Starting Cards',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _startNewRound,
            tooltip: 'Restart Round',
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
              // Top Stats Dashboard
              _buildStatsBar(),

              const SizedBox(height: 16),

              // Game Phase Content
              if (_phase == GamePhase.memorize) _buildMemorizePhase(),
              if (_phase == GamePhase.arrange) _buildArrangePhase(),
              if (_phase == GamePhase.roundResult) _buildResultPhase(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level / Card count badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.style_rounded,
                      size: 16,
                      color: Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Level: $_cardCount Cards',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Score & Timer
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $_roundScore',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatTime(_totalSecondsElapsed),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Phase 1: Memorization
  Widget _buildMemorizePhase() {
    final progress = _memorizeSecondsLeft / _totalMemorizeSeconds;

    return Column(
      children: [
        // Instruction banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFF97316)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memorize the Sequence ($_memorizeSecondsLeft s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Display Target Cards
        _buildCardsGrid(_targetSequence, showOrderBadge: true),

        const SizedBox(height: 24),

        // Skip / Ready Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _startArrangePhase,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              "I'm Ready to Arrange!",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Phase 2: Arrange / Recall
  Widget _buildArrangePhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Slots Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Arrange in Correct Order:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton.icon(
              onPressed: _onResetPlacedSlots,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Target Slots
        _buildSlotsGrid(),

        const SizedBox(height: 24),

        // Available Cards Deck
        const Text(
          'Tap a card to place in slot:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 10),

        if (_userSequence.isNotEmpty)
          _buildAvailableDeckGrid()
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'All cards placed! Checking sequence...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Phase 3: Round Result (Win / Retry)
  Widget _buildResultPhase() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isSuccessRound
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444))
                .withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _isSuccessRound
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSuccessRound
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
            ),
            child: Icon(
              _isSuccessRound
                  ? Icons.emoji_events_rounded
                  : Icons.highlight_off_rounded,
              color: _isSuccessRound
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isSuccessRound ? 'Perfect Match!' : 'Order Was Incorrect',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _isSuccessRound
                  ? const Color(0xFF065F46)
                  : const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSuccessRound
                ? 'Great memory! Advancing to Level ${_cardCount + 2} (${_cardCount + 2} cards).'
                : 'Take your time and try this sequence again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Correct sequence comparison preview
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Correct Sequence:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildMiniSequenceRow(_targetSequence),

          const SizedBox(height: 22),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccessRound
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSuccessRound ? _onNextRound : _onRetryRound,
              child: Text(
                _isSuccessRound ? 'Next Round (+2 Cards)' : 'Try Again',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid(List<GameColorCard> cards, {bool showOrderBadge = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 420 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildSingleCardItem(
              card,
              badgeText: showOrderBadge ? '#${index + 1}' : null,
            );
          },
        );
      },
    );
  }

  Widget _buildSlotsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 420 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cardCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final card = _userPlacedSlots[index];
            if (card == null) {
              // Empty slot placeholder
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Slot',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Placed card in slot (tap to remove)
            return GestureDetector(
              onTap: () => _onSlotTappedToReturn(index),
              child: _buildSingleCardItem(
                card,
                badgeText: '#${index + 1}',
                showRemoveIcon: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableDeckGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 420 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _userSequence.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final card = _userSequence[index];
            return GestureDetector(
              onTap: () => _onCardTappedToPlace(card),
              child: _buildSingleCardItem(card),
            );
          },
        );
      },
    );
  }

  Widget _buildSingleCardItem(
    GameColorCard card, {
    String? badgeText,
    bool showRemoveIcon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [card.color, card.darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: card.darkColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient decoration circle
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Order Badge
          if (badgeText != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // Remove Icon Badge
          if (showRemoveIcon)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),

          // Card content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(card.icon, size: 28, color: Colors.white),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    card.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMiniSequenceRow(List<GameColorCard> cards) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards.map((c) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.color, c.darkColor]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(c.icon, size: 16, color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }
}
