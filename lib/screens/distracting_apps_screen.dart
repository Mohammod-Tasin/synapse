/// Screen for selecting distracting apps
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/services/accessibility_permission_service.dart';

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSelected;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSelected = false,
  });

  factory InstalledApp.fromMap(
    Map<Object?, Object?> map, {
    bool isSelected = false,
  }) {
    return InstalledApp(
      packageName: (map['packageName'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? '',
      isSelected: isSelected,
    );
  }

  InstalledApp copyWith({bool? isSelected}) {
    return InstalledApp(
      packageName: packageName,
      appName: appName,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class DistractingAppsScreen extends StatefulWidget {
  const DistractingAppsScreen({super.key});

  @override
  State<DistractingAppsScreen> createState() => _DistractingAppsScreenState();
}

class _DistractingAppsScreenState extends State<DistractingAppsScreen> {
  final AccessibilityPermissionService _permissionService =
      AccessibilityPermissionService();

  List<InstalledApp> _apps = [];
  List<InstalledApp> _filteredApps = [];
  final Map<String, int> _appIndexByPackage = <String, int>{};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appsList = await _permissionService.getInstalledApps();
      final selectedPackages = await _permissionService.getDistractingApps();

      if (!mounted) return;

      final apps = appsList.map((item) {
        final map = item as Map<Object?, Object?>;
        return InstalledApp.fromMap(
          map,
          isSelected: selectedPackages.contains(map['packageName']),
        );
      }).toList();

      // Sort by selected first, then by name
      apps.sort((a, b) {
        if (a.isSelected != b.isSelected) {
          return a.isSelected ? -1 : 1;
        }
        return a.appName.compareTo(b.appName);
      });

      setState(() {
        _apps = apps;
        _filteredApps = List<InstalledApp>.from(apps);
        _appIndexByPackage
          ..clear()
          ..addEntries(
            _apps.asMap().entries.map(
              (entry) => MapEntry(entry.value.packageName, entry.key),
            ),
          );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load apps: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredApps = List<InstalledApp>.from(_apps);
        } else {
          final lowerQuery = query.toLowerCase();
          _filteredApps = _apps
              .where(
                (app) =>
                    app.appName.toLowerCase().contains(lowerQuery) ||
                    app.packageName.toLowerCase().contains(lowerQuery),
              )
              .toList(growable: false);
        }
      });
    });
  }

  void _toggleAppSelection(int index) {
    final app = _filteredApps[index];
    final newSelection = !app.isSelected;

    setState(() {
      _filteredApps[index] = app.copyWith(isSelected: newSelection);

      // Update in main list
      final mainIndex = _appIndexByPackage[app.packageName] ?? -1;
      if (mainIndex >= 0 && mainIndex < _apps.length) {
        _apps[mainIndex] = _apps[mainIndex].copyWith(isSelected: newSelection);
      }
    });
  }

  Future<void> _saveSelection() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final selectedPackages = _apps
          .where((app) => app.isSelected)
          .map((app) => app.packageName)
          .toList();

      final success = await _permissionService.setDistractingApps(
        selectedPackages,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedPackages.isEmpty
                  ? 'No distracting apps selected'
                  : 'Selected ${selectedPackages.length} app(s)',
            ),
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save selection')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Distracting Apps'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // App list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No apps found'
                          : 'No apps matching "$_searchQuery"',
                      style: AppTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: 2,
                        ),
                        onTap: () => _toggleAppSelection(index),
                        title: Text(app.appName),
                        subtitle: Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodySmall,
                        ),
                        trailing: Checkbox(
                          value: app.isSelected,
                          onChanged: (_) => _toggleAppSelection(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _saveSelection,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check),
      ),
    );
  }
}
