import 'package:flutter/material.dart';

// Date: 2025-12-25
// Purpose: A reusable 3-pane layout (Left, Middle, Right) with resizable capabilities.
// Default ratio: 10:10:80.
class PlanningLayout extends StatefulWidget {
  final Widget? leftPane;
  final Widget? middlePane;
  final List<Widget> extraPanes;
  final Widget rightPane;

  const PlanningLayout({
    super.key,
    this.leftPane,
    this.middlePane,
    this.extraPanes = const [],
    required this.rightPane,
  });

  @override
  State<PlanningLayout> createState() => _PlanningLayoutState();
}

class _PlanningLayoutState extends State<PlanningLayout> {
  double? _leftWidth;
  double? _middleWidth;
  List<double> _extraWidths = [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        
        // Initialize widths
        _leftWidth ??= totalWidth * 0.18; // Slightly wider for Left Pane
        _middleWidth ??= totalWidth * 0.25; // Much wider for Editor to fit buttons
        if (_extraWidths.length != widget.extraPanes.length) {
            _extraWidths = List.filled(widget.extraPanes.length, totalWidth * 0.20);
        }

        // Clamp safeguards
        if (_leftWidth! < 50) _leftWidth = 50;
        if (_middleWidth! < 50) _middleWidth = 50;

        List<Widget> children = [];

        // --- Pane 1: Favorites (Left) ---
        if (widget.leftPane != null) {
          children.add(SizedBox(
            width: _leftWidth,
            child: widget.leftPane!,
          ));
          children.add(_buildResizer((delta) {
            setState(() {
              _leftWidth = (_leftWidth! + delta).clamp(50.0, totalWidth * 0.4);
            });
          }));
        }

        // --- Pane 2: Editor (Middle) ---
        if (widget.middlePane != null) {
          children.add(SizedBox(
            width: _middleWidth,
            child: widget.middlePane!,
          ));
          children.add(_buildResizer((delta) {
            setState(() {
              _middleWidth = (_middleWidth! + delta).clamp(50.0, totalWidth * 0.4);
            });
          }));
        }
        
        // --- Extra Panes (Spots, Trips...) ---
        for (int i = 0; i < widget.extraPanes.length; i++) {
           children.add(SizedBox(
              width: _extraWidths[i],
              child: widget.extraPanes[i],
           ));
           children.add(_buildResizer((delta) {
              setState(() {
                 _extraWidths[i] = (_extraWidths[i] + delta).clamp(50.0, totalWidth * 0.4);
              });
           }));
        }

        // --- Pane 3: Map (Right) ---
        children.add(Expanded(child: widget.rightPane));

        return Row(children: children);
      },
    );
  }

  Widget _buildResizer(Function(double) onDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        onDrag(details.delta.dx);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 8,
          color: Colors.grey[300],
          child: Center(
            child: Container(
              width: 2,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
