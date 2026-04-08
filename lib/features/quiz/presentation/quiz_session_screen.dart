import 'dart:async';

import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/domain/entities/question.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  const QuizSessionScreen({super.key, required this.setId});

  final String setId;

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int _index = 0;
  int? _selectedOption;
  int _score = 0;
  bool _answered = false;
  bool _complete = false;
  bool _resultSubmitted = false;
  Duration? _remainingTime;
  Timer? _quizTimer;

  void _selectAnswer(Question question, int optionIndex) {
    if (_answered || _complete) {
      return;
    }

    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      if (optionIndex == question.correctIndex) {
        _score += 1;
      }
    });
  }

  void _nextQuestion(QuestionSet set) {
    if (_index >= set.questions.length - 1) {
      _stopTimer();
      setState(() => _complete = true);
      _submitQuizResult(set);
      return;
    }

    setState(() {
      _index += 1;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selectedOption = null;
      _score = 0;
      _answered = false;
      _complete = false;
      _resultSubmitted = false;
      _remainingTime = null;
    });
    _stopTimer();
  }

  Future<void> _submitQuizResult(QuestionSet set) async {
    if (_resultSubmitted || !mounted) {
      return;
    }

    try {
      await ref.read(authRepositoryProvider).submitQuizResult(
        quizId: set.id,
        score: _score,
        total: set.questions.length,
      );

      if (mounted) {
        final _ = ref.refresh(authStateProvider);
      }
    } catch (_) {
      // Ignore submission errors in the quiz flow.
    } finally {
      if (mounted) {
        setState(() {
          _resultSubmitted = true;
        });
      }
    }
  }

  void _startTimer(QuestionSet set) {
    _stopTimer();
    _remainingTime = Duration(minutes: set.estimatedMinutes);
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime == null) {
        timer.cancel();
        return;
      }

      if (_remainingTime!.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
          _complete = true;
        });
        if (mounted) {
          _submitQuizResult(set);
        }
        return;
      }

      setState(() {
        _remainingTime = Duration(seconds: _remainingTime!.inSeconds - 1);
      });
    });
  }

  void _stopTimer() {
    _quizTimer?.cancel();
    _quizTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '$minutes:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final questionSetAsync = ref.watch(questionSetProvider(widget.setId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz session')),
      body: GradientBackdrop(
        child: questionSetAsync.when(
          data: (QuestionSet? set) {
            if (set == null || set.questions.isEmpty) {
              return const Center(
                child: GlassCard(child: Text('Question set not found.')),
              );
            }

            if (_remainingTime == null && !_complete) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_complete) {
                  _startTimer(set);
                }
              });
            }

            if (_complete) {
              return _QuizResult(set: set, score: _score, onRetry: _restart);
            }

            final int total = set.questions.length;
            final int safeIndex = _index.clamp(0, total - 1);
            final Question question = set.questions[safeIndex];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: <Widget>[
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _LabelChip(text: set.grade, color: AppColors.primary),
                          const SizedBox(width: 8),
                          _LabelChip(text: set.subject, color: set.accentColor),
                          const Spacer(),
                          Text(
                            '${safeIndex + 1}/$total',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _remainingTime != null
                            ? 'Time left: ${_formatDuration(_remainingTime!)}'
                            : 'Estimated: ${set.estimatedMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: (safeIndex + 1) / total,
                          backgroundColor: AppColors.border.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        questionSetTitle(set),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: set.accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Column(
                    key: ValueKey<String>(question.id),
                    children: <Widget>[
                      ...List<Widget>.generate(question.options.length, (
                        int optionIndex,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            index: optionIndex,
                            text: question.options[optionIndex],
                            selected: _selectedOption == optionIndex,
                            answered: _answered,
                            correctIndex: question.correctIndex,
                            onTap: () => _selectAnswer(question, optionIndex),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (_answered) ...<Widget>[
                  const SizedBox(height: 4),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selectedOption == question.correctIndex
                              ? 'Correct'
                              : 'Not quite',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _selectedOption == question.correctIndex
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _answered ? () => _nextQuestion(set) : null,
                    child: Text(
                      safeIndex == total - 1 ? 'Finish quiz' : 'Next question',
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) =>
              Center(child: GlassCard(child: Text(error.toString()))),
        ),
      ),
    );
  }
}

String questionSetTitle(QuestionSet set) {
  return '${set.topic} • ${set.estimatedMinutes} min';
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.answered,
    required this.correctIndex,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool answered;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isCorrect = index == correctIndex;
    final bool isWrongChoice = answered && selected && !isCorrect;
    final bool showCorrect = answered && isCorrect;

    Color borderColor = AppColors.border;
    Color backgroundColor = colors.surface;
    Color iconColor = AppColors.textMuted;

    if (selected) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.08);
      iconColor = AppColors.primary;
    }
    if (showCorrect) {
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.12);
      iconColor = AppColors.success;
    }
    if (isWrongChoice) {
      borderColor = AppColors.danger;
      backgroundColor = AppColors.danger.withValues(alpha: 0.12);
      iconColor = AppColors.danger;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          if (selected || showCorrect || isWrongChoice)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  showCorrect
                      ? Icons.check_circle_rounded
                      : isWrongChoice
                      ? Icons.cancel_rounded
                      : selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.circle_outlined,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).slideX(begin: 0.03, end: 0);
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuizResult extends StatelessWidget {
  const _QuizResult({
    required this.set,
    required this.score,
    required this.onRetry,
  });

  final QuestionSet set;
  final int score;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final int total = set.questions.length;
    final double accuracy = total == 0 ? 0 : score / total;
    final bool isExcellent = accuracy >= 0.8;
    final bool isGood = accuracy >= 0.5;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: <Widget>[
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      isExcellent
                          ? AppColors.success
                          : isGood
                          ? AppColors.primary
                          : AppColors.danger,
                      (isExcellent
                              ? AppColors.success
                              : isGood
                              ? AppColors.primary
                              : AppColors.danger)
                          .withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (isExcellent
                              ? AppColors.success
                              : isGood
                              ? AppColors.primary
                              : AppColors.danger)
                          .withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isExcellent
                        ? Icons.emoji_events_rounded
                        : isGood
                        ? Icons.thumb_up_rounded
                        : Icons.psychology_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                isExcellent
                    ? 'Excellent!'
                    : isGood
                    ? 'Good Job!'
                    : 'Keep Practicing!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'You scored $score out of $total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: <Widget>[
            _StatBox(
              label: 'Accuracy',
              value: '${(accuracy * 100).round()}%',
              icon: Icons.track_changes_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 16),
            _StatBox(
              label: 'Success Rate',
              value: isExcellent ? 'High' : isGood ? 'Medium' : 'Low',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
          ],
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: set.accentColor),
                  const SizedBox(width: 12),
                  Text(
                    'Topic breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Grade', value: set.grade),
              const Divider(height: 24, thickness: 0.5),
              _DetailRow(label: 'Subject', value: set.subject),
              const Divider(height: 24, thickness: 0.5),
              _DetailRow(label: 'Topic', value: set.topic),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Retry this set',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to practice',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ).animate().fadeIn(delay: 1100.ms),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

