
import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';

class DashboardGridLayout extends StatefulWidget {
  final List<PanelWidgetConfig> widgets;
  final bool isEditMode;
  final Function(PanelWidgetConfig) onWidgetUpdate;
  final Function(PanelWidgetConfig) onWidgetEdit;
  final Function(String) onWidgetDelete;
  final Widget Function(PanelWidgetConfig) childBuilder;

  const DashboardGridLayout({
    super.key,
    required this.widgets,
    required this.isEditMode,
    required this.onWidgetUpdate,
    required this.onWidgetEdit,
    required this.onWidgetDelete,
    required this.childBuilder,
  });

  @override
  State<DashboardGridLayout> createState() => _DashboardGridLayoutState();
}

class _DashboardGridLayoutState extends State<DashboardGridLayout> {
  final double cellSize = 40.0; // Base unit for grid
  final double gridSpacing = 8.0;

  // Temporary state for dragging/resizing
  String? _activeWidgetId;
  Offset? _dragOffset;
  Offset? _resizeOffset;
  PanelWidgetConfig? _activeConfig;
  bool _isResizing = false;
  
  // Drag start position to calculate delta
  double? _startX;
  double? _startY;
  double? _startWidth;
  double? _startHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Standard ThingsBoard is 24 columns usually.
          // We use 8 columns on mobile (< 600px) and 24 on desktop > 600px.
          int columns = constraints.maxWidth < 600 ? 8 : 24;
          
          final double effectiveWidth = constraints.maxWidth;
          // Ensure we don't divide by zero or have negative spacing
          double cellWidth = (effectiveWidth - (gridSpacing * (columns - 1))) / columns;
          if (cellWidth < 1) cellWidth = 10; // Safety fallback
          
          double cellHeight = cellWidth; // Square cells are often easier, or 0.8 aspect
          // Using square cells for "finer" control is usually better for "reduced" grid.
          // Let's stick to user's request for "reduced" -> finer granularity.
          // Square seems most versatile.
          
          // Calculate total height based on lowest widget in the NEW grid context
          double maxY = 0;
          for (var w in widget.widgets) {
            if ((w.y + w.height) > maxY) maxY = w.y + w.height;
          }
          // Dynamic height
          final containerHeight = (maxY * (cellHeight + gridSpacing)) + 400;

          return Container(
            height: containerHeight,
            width: double.infinity,
            color: Colors.transparent, // Hit test for empty space
            child: Stack(
              children: [
                if (widget.isEditMode) _buildGridBackground(columns, cellWidth, cellHeight, containerHeight),
                ...widget.widgets.map((config) {
                   return _buildWidgetPositioned(config, cellWidth, cellHeight, constraints.maxWidth);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridBackground(int columns, double cellWidth, double cellHeight, double totalHeight) {
    return Positioned.fill(
      child: CustomPaint(
        painter: GridPainter(
          columns: columns,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          spacing: gridSpacing,
          color: Theme.of(context).dividerColor.withOpacity(0.05), // Lighter grid
        ),
      ),
    );
  }

  Widget _buildWidgetPositioned(PanelWidgetConfig config, double cellWidth, double cellHeight, double maxWidth) {
    // Current layout values (snap to grid)
    double top = config.y * (cellHeight + gridSpacing);
    double left = config.x * (cellWidth + gridSpacing);
    double width = config.width * cellWidth + ((config.width - 1) * gridSpacing);
    double height = config.height * cellHeight + ((config.height - 1) * gridSpacing);

    // Override if this is the active widget being manipulated
    /* 
       Optimally, we update the config state in real-time or use local state.
       Here we use the config passed in. 
       If we want smooth dragging, we might need local overrides.
       For now, let's implement the drag logic triggers. 
    */

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: GestureDetector(
        onPanStart: widget.isEditMode ? (details) => _onPanStart(details, config) : null,
        onPanUpdate: widget.isEditMode ? (details) => _onPanUpdate(details, config, cellWidth, cellHeight, maxWidth) : null,
        onPanEnd: widget.isEditMode ? (details) => _onPanEnd(details, config) : null,
        child: Stack(
          children: [
            widget.childBuilder(config),
            if (widget.isEditMode) _buildResizeHandles(config, cellWidth, cellHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandles(PanelWidgetConfig config, double cellWidth, double cellHeight) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanStart: (details) => _onResizeStart(details, config),
        onPanUpdate: (details) => _onResizeUpdate(details, config, cellWidth, cellHeight),
        onPanEnd: (details) => _onResizeEnd(details, config),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(15)),
          ),
          child: const Icon(Icons.drag_handle, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details, PanelWidgetConfig config) {
    setState(() {
      _activeWidgetId = config.id;
      _activeConfig = config;
      _isResizing = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, PanelWidgetConfig config, double cellWidth, double cellHeight, double maxWidth) {
     if (_activeWidgetId != config.id) return;
     
     // Calculate delta in grid units
     double dx = details.delta.dx / (cellWidth + gridSpacing);
     double dy = details.delta.dy / (cellHeight + gridSpacing);

     double newX = config.x + dx;
     double newY = config.y + dy;

     // Clamp to bounds
     if (newX < 0) newX = 0;
     if (newY < 0) newY = 0;

     // Update visual immediately? 
     // We can just call onWidgetUpdate which updates the Provider.
     // But that might trigger full rebuilds. Ideally we use local state for smooth drag.
     // But for simplicity/correctness first:
     
     widget.onWidgetUpdate(config.copyWith(
       x: newX,
       y: newY,
     ));
  }

  void _onPanEnd(DragEndDetails details, PanelWidgetConfig config) {
    // Snap to nearest integer
    double snappedX = config.x.roundToDouble();
    double snappedY = config.y.roundToDouble();
    
    widget.onWidgetUpdate(config.copyWith(
      x: snappedX,
      y: snappedY,
    ));
    
    setState(() {
      _activeWidgetId = null;
      _activeConfig = null;
    });
  }

  // --- Resize Logic ---

  void _onResizeStart(DragStartDetails details, PanelWidgetConfig config) {
     // Stop propagation to drag
     setState(() {
      _activeWidgetId = config.id;
      _activeConfig = config;
      _isResizing = true;
     });
  }

  void _onResizeUpdate(DragUpdateDetails details, PanelWidgetConfig config, double cellWidth, double cellHeight) {
     double dx = details.delta.dx / (cellWidth + gridSpacing);
     double dy = details.delta.dy / (cellHeight + gridSpacing);

     double newW = config.width + dx;
     double newH = config.height + dy;

     if (newW < 1) newW = 1;
     if (newH < 1) newH = 1;

     widget.onWidgetUpdate(config.copyWith(
       width: newW,
       height: newH,
     ));
  }

  void _onResizeEnd(DragEndDetails details, PanelWidgetConfig config) {
     double snappedW = config.width.roundToDouble();
     double snappedH = config.height.roundToDouble();
     if (snappedW < 1) snappedW = 1;
     if (snappedH < 1) snappedH = 1;

     widget.onWidgetUpdate(config.copyWith(
       width: snappedW,
       height: snappedH,
     ));

     setState(() {
      _activeWidgetId = null;
      _activeConfig = null;
      _isResizing = false;
    });
  }
}

class GridPainter extends CustomPainter {
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final double spacing;
  final Color color;

  GridPainter({
    required this.columns, 
    required this.cellWidth, 
    required this.cellHeight,
    required this.spacing,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw vertical lines
    // Actually, drawing dots or grid cells is better
    // Let's draw rectangles for cells
    
    // We don't know exact total height here effectively unless passed.
    // Assuming size.height covers it.
    
    int rows = (size.height / (cellHeight + spacing)).ceil();
    
    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        double left = i * (cellWidth + spacing);
        double top = j * (cellHeight + spacing);
        
        // Draw a light rect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cellWidth, cellHeight),
            const Radius.circular(8),
          ), 
          paint
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.columns != columns || oldDelegate.cellWidth != cellWidth;
  }
}
