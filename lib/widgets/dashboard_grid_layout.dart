
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
    // If this widget is currently being dragged/resized, use the local temporary config
    final displayConfig = (_activeWidgetId == config.id && _activeConfig != null) 
        ? _activeConfig! 
        : config;

    // Current layout values (snap to grid or smooth position)
    double top = displayConfig.y * (cellHeight + gridSpacing);
    double left = displayConfig.x * (cellWidth + gridSpacing);
    double width = displayConfig.width * cellWidth + ((displayConfig.width - 1) * gridSpacing);
    double height = displayConfig.height * cellHeight + ((displayConfig.height - 1) * gridSpacing);

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: GestureDetector(
        onPanStart: widget.isEditMode ? (details) => _onPanStart(details, config) : null,
        onPanUpdate: widget.isEditMode ? (details) => _onPanUpdate(details, cellWidth, cellHeight) : null,
        onPanEnd: widget.isEditMode ? (details) => _onPanEnd(details) : null,
        child: Stack(
          children: [
            widget.childBuilder(config), // Keep inner content static, don't rebuild it constantly? Or pass displayConfig if content changes? Usually static is fine.
            if (widget.isEditMode) _buildResizeHandles(config, cellWidth, cellHeight),
            // Overlay to block inner interactions while dragging
            if (widget.isEditMode && _activeWidgetId == config.id)
               Container(color: Colors.transparent), 
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
        onPanUpdate: (details) => _onResizeUpdate(details, cellWidth, cellHeight),
        onPanEnd: (details) => _onResizeEnd(details),
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
      _activeConfig = config; // Clone start config
      _isResizing = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double cellWidth, double cellHeight) {
     if (_activeConfig == null) return;
     
     // Calculate delta in grid units
     double dx = details.delta.dx / (cellWidth + gridSpacing);
     double dy = details.delta.dy / (cellHeight + gridSpacing);

     double newX = _activeConfig!.x + dx;
     double newY = _activeConfig!.y + dy;

     if (newX < 0) newX = 0;
     if (newY < 0) newY = 0;

     // Update LOCAL state only
     setState(() {
       _activeConfig = _activeConfig!.copyWith(x: newX, y: newY);
     });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeConfig == null) return;

    // Snap to nearest integer
    double snappedX = _activeConfig!.x.roundToDouble();
    double snappedY = _activeConfig!.y.roundToDouble();
    
    final finalConfig = _activeConfig!.copyWith(
      x: snappedX,
      y: snappedY,
    );

    // Check collision with OTHER widgets
    bool hasCollision = _checkCollision(finalConfig);

    if (hasCollision) {
        // Revert to original position (implied by not calling update, or we could explicitly reset)
        // Since we are cancelling, we just clear local state. The parent state hasn't changed yet.
        // Option: Show snackbar?
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot place widget here: Collision detected!'), duration: Duration(milliseconds: 500)),
        );
    } else {
        // Commit to parent/DB
        widget.onWidgetUpdate(finalConfig);
    }
    
    setState(() {
      _activeWidgetId = null;
      _activeConfig = null;
    });
  }

  bool _checkCollision(PanelWidgetConfig candidate) {
    // Treat candidate as Rect
    // We use a small margin to avoid "touching" errors? Integer grid should be strict.
    final Rect candidateRect = Rect.fromLTWH(
      candidate.x, 
      candidate.y, 
      candidate.width, 
      candidate.height
    );

    for (var other in widget.widgets) {
      if (other.id == candidate.id) continue; // Skip self

      final Rect otherRect = Rect.fromLTWH(
        other.x, 
        other.y, 
        other.width, 
        other.height
      );

      if (candidateRect.overlaps(otherRect)) {
        // Calculate intersection area to be sure it's not just touching edges
        // Rect.overlaps returns true for touching edges? 
        // Logic: left < right && right > left ...
        // If x=0,w=1 (0..1) and x=1,w=1 (1..2). 
        // 0+1 > 1 is FALSE. So touching is NOT overlapping in float logic usually.
        // But let's be safe.
        // Intersection
        final intersect = candidateRect.intersect(otherRect);
        if (intersect.width > 0.1 && intersect.height > 0.1) {
           return true; 
        }
      }
    }
    return false;
  }

  // --- Resize Logic ---

  void _onResizeStart(DragStartDetails details, PanelWidgetConfig config) {
     setState(() {
      _activeWidgetId = config.id;
      _activeConfig = config;
      _isResizing = true;
     });
  }

  void _onResizeUpdate(DragUpdateDetails details, double cellWidth, double cellHeight) {
     if (_activeConfig == null) return;

     double dx = details.delta.dx / (cellWidth + gridSpacing);
     double dy = details.delta.dy / (cellHeight + gridSpacing);

     double newW = _activeConfig!.width + dx;
     double newH = _activeConfig!.height + dy;

     if (newW < 1) newW = 1;
     if (newH < 1) newH = 1;

     setState(() {
       _activeConfig = _activeConfig!.copyWith(width: newW, height: newH);
     });
  }

  void _onResizeEnd(DragEndDetails details) {
     if (_activeConfig == null) return;

     double snappedW = _activeConfig!.width.roundToDouble();
     double snappedH = _activeConfig!.height.roundToDouble();
     if (snappedW < 1) snappedW = 1;
     if (snappedH < 1) snappedH = 1;

     final finalConfig = _activeConfig!.copyWith(
       width: snappedW,
       height: snappedH,
     );

     widget.onWidgetUpdate(finalConfig);

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
