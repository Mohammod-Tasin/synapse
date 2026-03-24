library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:no_to_distraction/services/quick_block_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class QuickBlockScreen extends StatefulWidget {
  const QuickBlockScreen({super.key});

  @override
  State<QuickBlockScreen> createState() => _QuickBlockScreenState();
}

class _QuickBlockScreenState extends State<QuickBlockScreen> {
  final QuickBlockService _quickBlockService = QuickBlockService();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  final Set<String> _selectedPackages = <String>{};
  final Map<String, _DurationSpec> _assignedDurations =
      <String, _DurationSpec>{};

  final TextEditingController _monthsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _daysController = TextEditingController(
    text: '0',
  );
  final TextEditingController _hoursController = TextEditingController(
    text: '0',
  );
  final TextEditingController _minutesController = TextEditingController(
    text: '30',
  );

  List<AppInfo> _installedApps = <AppInfo>[];
  List<AppInfo> _visibleApps = <AppInfo>[];
  QuickBlockStatus? _status;

  bool _isLoadingApps = true;
  bool _isSubmitting = false;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _loadQuickBlockStatus();

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      // Avoid unnecessary rebuild pressure while user is typing in search.
      if (_searchFocusNode.hasFocus) {
        return;
      }

      final status = _status;
      if (status == null || status.rules.isEmpty) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _monthsController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      _isLoadingApps = true;
    });

    try {
      final apps = await InstalledApps.getInstalledApps(
        withIcon: false,
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
      );

      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) {
        return;
      }

      setState(() {
        _installedApps = apps;
        _visibleApps = apps;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load installed apps.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApps = false;
        });
      }
    }
  }

  Future<void> _loadQuickBlockStatus() async {
    final status = await _quickBlockService.getQuickBlockStatus();
    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
    });
  }

  void _applySearch(String value) {
    _searchDebounce?.cancel();

    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _visibleApps = _installedApps;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }

      final filtered = _installedApps.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _visibleApps = filtered;
      });
    });
  }

  _DurationSpec _readDurationInputs() {
    int parseValue(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

    return _DurationSpec(
      months: parseValue(_monthsController),
      days: parseValue(_daysController),
      hours: parseValue(_hoursController),
      minutes: parseValue(_minutesController),
    );
  }

  Duration _effectiveDuration() => _readDurationInputs().toDuration();

  bool _isDurationValid() {
    return _effectiveDuration().inMinutes >= 1;
  }

  void _applyDurationToSelected() {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select apps first.')));
      return;
    }

    final spec = _readDurationInputs();
    if (spec.toDuration().inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum duration is 1 minute.')),
      );
      return;
    }

    setState(() {
      for (final pkg in _selectedPackages) {
        _assignedDurations[pkg] = spec;
      }
    });
  }

  Future<void> _saveBlocks() async {
    if (_assignedDurations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assign duration to at least one app.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final payload = <String, int>{};

      _assignedDurations.forEach((pkg, spec) {
        final duration = spec.toDuration();
        if (duration.inMinutes >= 1) {
          payload[pkg] = nowMs + duration.inMilliseconds;
        }
      });

      if (payload.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum duration is 1 minute.')),
        );
        return;
      }

      final ok = await _quickBlockService.upsertQuickBlockRules(
        packageEndTimes: payload,
      );

      if (!mounted) {
        return;
      }

      if (ok) {
        await _loadQuickBlockStatus();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${payload.length} app block rules.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save Quick Block rules.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Native call failed for Quick Block.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _appNameOf(String packageName) {
    for (final app in _installedApps) {
      if (app.packageName == packageName) {
        return app.name;
      }
    }
    return packageName;
  }

  String _remainingText(int endTimeMs) {
    final remainingMs = endTimeMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) {
      return 'Expired';
    }

    final d = Duration(milliseconds: remainingMs);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final durationIsValid = _isDurationValid();
    final selectedCount = _selectedPackages.length;
    final filteredApps = _visibleApps;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Quick Block')),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: Select apps',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      focusNode: _searchFocusNode,
                      onChanged: _applySearch,
                      decoration: const InputDecoration(
                        hintText: 'Search app name or package',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'Step 2: Set duration',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _DurationInputsRow(
                      monthsController: _monthsController,
                      daysController: _daysController,
                      hoursController: _hoursController,
                      minutesController: _minutesController,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      durationIsValid
                          ? 'Selected duration: ${_readDurationInputs().asReadableText()}'
                          : 'Duration must be at least 1 minute',
                      style: AppTheme.bodySmall.copyWith(
                        color: durationIsValid ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: [
                        Chip(label: Text('$selectedCount selected')),
                        OutlinedButton(
                          onPressed: durationIsValid
                              ? _applyDurationToSelected
                              : null,
                          child: const Text('Apply'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _saveBlocks,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (_assignedDurations.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Assignments (${_assignedDurations.length})',
                              style: AppTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            ..._assignedDurations.entries.take(6).map((entry) {
                              final appName = _appNameOf(entry.key);
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '• $appName: ${entry.value.asReadableText()}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _assignedDurations.remove(entry.key);
                                        _selectedPackages.remove(entry.key);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (status != null && status.rules.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Blocks (${status.rules.length})',
                              style: AppTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            ...status.rules.take(8).map((rule) {
                              final appName = _appNameOf(rule.packageName);
                              return Text(
                                '• $appName: ${_remainingText(rule.endTimeMs)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _loadQuickBlockStatus,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: const Divider(height: 1)),
            if (_isLoadingApps)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              SliverList.separated(
                itemCount: filteredApps.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  final selected = _selectedPackages.contains(app.packageName);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedPackages.add(app.packageName);
                        } else {
                          _selectedPackages.remove(app.packageName);
                        }
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DurationInputsRow extends StatelessWidget {
  final TextEditingController monthsController;
  final TextEditingController daysController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;

  const _DurationInputsRow({
    required this.monthsController,
    required this.daysController,
    required this.hoursController,
    required this.minutesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DurationBox(
                controller: monthsController,
                label: 'Months',
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _DurationBox(controller: daysController, label: 'Days'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _DurationBox(controller: hoursController, label: 'Hours'),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _DurationBox(controller: minutesController, label: 'Min'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DurationBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DurationBox({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _DurationSpec {
  final int months;
  final int days;
  final int hours;
  final int minutes;

  const _DurationSpec({
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
  });

  Duration toDuration() {
    final m = months < 0 ? 0 : months;
    final d = days < 0 ? 0 : days;
    final h = hours < 0 ? 0 : hours;
    final min = minutes < 0 ? 0 : minutes;

    return Duration(days: (m * 30) + d, hours: h, minutes: min);
  }

  String asReadableText() {
    return '${months}mo ${days}d ${hours}h ${minutes}m';
  }
}
