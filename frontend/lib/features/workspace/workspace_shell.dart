import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/app_sidebar.dart';

class WorkspaceShell extends ConsumerStatefulWidget {
  final String areaId;
  final Widget child;

  const WorkspaceShell({super.key, required this.areaId, required this.child});

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedAreaIdProvider) != widget.areaId) {
        ref.read(selectedAreaIdProvider.notifier).state = widget.areaId;
        ref.read(dominoNotifierProvider.notifier).reset();
        ref.read(scenarioNotifierProvider.notifier).reset();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WorkspaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedAreaIdProvider.notifier).state = widget.areaId;
        ref.read(dominoNotifierProvider.notifier).reset();
        ref.read(scenarioNotifierProvider.notifier).reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppHeader(
        showSidebarToggle: !isDesktop,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: !isDesktop
          ? Drawer(
              child: AppSidebar(
                activeAreaId: widget.areaId,
                isCollapsed: false,
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              activeAreaId: widget.areaId,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
