import 'dart:typed_data';
import 'package:flutter/material.dart';

class AnnotationPage extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> detectedBoxes;

  const AnnotationPage({
    super.key,
    required this.imageBytes,
    required this.detectedBoxes,
  });

  @override
  State<AnnotationPage> createState() => _AnnotationPageState();
}

class _AnnotationPageState extends State<AnnotationPage> {
  List<Map<String, dynamic>> boxes = [];
  List<List<Map<String, dynamic>>> undoStack = [];
  List<List<Map<String, dynamic>>> redoStack = [];

  Offset? startDrag;
  Offset? currentDrag;
  int? selectedIndex;
  final GlobalKey imageKey = GlobalKey();
  bool isResizing = false;
  final TextEditingController _labelController = TextEditingController();
  final ScrollController _drawerScrollController = ScrollController();
  bool _drawerExpanded = false;

  @override
  void initState() {
    super.initState();
    boxes = List.from(widget.detectedBoxes);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _drawerScrollController.dispose();
    super.dispose();
  }

  void _pushUndo() {
    undoStack.add(boxes.map((e) => Map<String, dynamic>.from(e)).toList());
    redoStack.clear();
  }

  void _addNewBox(Rect rect) {
    _pushUndo();
    boxes.add({
      'box': [rect.left, rect.top, rect.right, rect.bottom],
      'label': 'New Label',
    });
    selectedIndex = boxes.length - 1;
    _showLabelDialog();
    setState(() {});
  }

  void _updateBoxPosition(int index, Offset delta) {
    _pushUndo();
    final box = boxes[index]['box'];
    final newBox = [
      box[0] + delta.dx,
      box[1] + delta.dy,
      box[2] + delta.dx,
      box[3] + delta.dy,
    ];
    boxes[index]['box'] = newBox;
    setState(() {});
  }

  void _showLabelDialog() {
    if (selectedIndex == null) return;

    _labelController.text = boxes[selectedIndex!]['label'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Label'),
        content: TextField(
          controller: _labelController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter label for this object',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_labelController.text.isNotEmpty) {
                _pushUndo();
                boxes[selectedIndex!]['label'] = _labelController.text;
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (undoStack.isNotEmpty) {
      redoStack.add(boxes);
      boxes = undoStack.removeLast();
      selectedIndex = null;
      setState(() {});
    }
  }

  void _redo() {
    if (redoStack.isNotEmpty) {
      undoStack.add(boxes);
      boxes = redoStack.removeLast();
      selectedIndex = null;
      setState(() {});
    }
  }

  void _deleteSelectedBox() {
    if (selectedIndex != null && selectedIndex! < boxes.length) {
      _pushUndo();
      boxes.removeAt(selectedIndex!);
      selectedIndex = null;
      setState(() {});
    }
  }

  void _resizeBox(int index, Offset delta) {
    _pushUndo();
    final box = boxes[index]['box'];
    double x1 = box[0], y1 = box[1], x2 = box[2], y2 = box[3];

    x2 += delta.dx;
    y2 += delta.dy;

    if ((x2 - x1).abs() >= 10 && (y2 - y1).abs() >= 10) {
      boxes[index]['box'] = [
        x1 < x2 ? x1 : x2,
        y1 < y2 ? y1 : y2,
        x1 > x2 ? x1 : x2,
        y1 > y2 ? y1 : y2,
      ];
      setState(() {});
    }
  }

  void _bringToFront(int index) {
    if (index >= 0 && index < boxes.length) {
      final box = boxes.removeAt(index);
      boxes.add(box);
      selectedIndex = boxes.length - 1;
      setState(() {});
    }
  }

  int? _getBoxAtPoint(Offset point) {
    for (int i = boxes.length - 1; i >= 0; i--) {
      final box = boxes[i]['box'];
      final rect = Rect.fromLTRB(box[0], box[1], box[2], box[3]);
      if (rect.contains(point)) {
        return i;
      }
    }
    return null;
  }

  String? _getResizeCorner(int index, Offset point) {
    if (index == null) return null;

    final box = boxes[index]['box'];
    final rect = Rect.fromLTRB(box[0], box[1], box[2], box[3]);
    const handleSize = 12.0;

    final bottomRight = Offset(rect.right, rect.bottom);
    if ((point - bottomRight).distance <= handleSize) {
      return 'bottomRight';
    }

    return null;
  }

  void _toggleDrawer() {
    setState(() {
      _drawerExpanded = !_drawerExpanded;
    });
  }

  Widget _buildBottomDrawer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _drawerExpanded ? 200 : 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drawer handle
          GestureDetector(
            onTap: _toggleDrawer,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[500],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (_drawerExpanded)
            Expanded(
              child: ListView.builder(
                controller: _drawerScrollController,
                itemCount: boxes.length,
                itemBuilder: (context, index) {
                  final box = boxes[index];
                  final isSelected = selectedIndex == index;
                  return ListTile(
                    title: Text(
                      box['label'] ?? 'Unlabeled',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '(${box['box'][0].toStringAsFixed(0)}, '
                          '${box['box'][1].toStringAsFixed(0)}) - '
                          '(${box['box'][2].toStringAsFixed(0)}, '
                          '${box['box'][3].toStringAsFixed(0)})',
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        _pushUndo();
                        boxes.removeAt(index);
                        if (selectedIndex == index) {
                          selectedIndex = null;
                        } else if (selectedIndex != null && selectedIndex! > index) {
                          selectedIndex = selectedIndex! - 1;
                        }
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      _bringToFront(index);
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  );
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                '${boxes.length} annotations',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annotation Page"),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: undoStack.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: selectedIndex != null ? _deleteSelectedBox : null,
            tooltip: 'Delete selected box',
          ),
          if (selectedIndex != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showLabelDialog,
              tooltip: 'Edit label',
            ),
          if (selectedIndex != null)
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: () => _bringToFront(selectedIndex!),
              tooltip: 'Bring to front',
            ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _toggleDrawer,
            tooltip: 'Show annotations list',
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

              return GestureDetector(
                onTapDown: (details) {
                  final position = details.localPosition;
                  final boxIndex = _getBoxAtPoint(position);

                  if (boxIndex != null) {
                    _bringToFront(boxIndex);
                  } else {
                    setState(() {
                      selectedIndex = null;
                    });
                  }
                },
                onPanStart: (details) {
                  final position = details.localPosition;

                  // Check if we're resizing the selected box
                  if (selectedIndex != null) {
                    final corner = _getResizeCorner(selectedIndex!, position);
                    if (corner != null) {
                      setState(() {
                        isResizing = true;
                        startDrag = position;
                        currentDrag = position;
                      });
                      return;
                    }
                  }

                  // Check if we're moving the selected box
                  if (selectedIndex != null) {
                    final box = boxes[selectedIndex!]['box'];
                    final rect = Rect.fromLTRB(box[0], box[1], box[2], box[3]);
                    if (rect.contains(position)) {
                      setState(() {
                        startDrag = position;
                        currentDrag = position;
                      });
                      return;
                    }
                  }

                  // Otherwise check if we can start drawing a new box
                  final boxIndex = _getBoxAtPoint(position);
                  if (boxIndex == null) {
                    setState(() {
                      selectedIndex = null;
                      startDrag = position;
                      currentDrag = position;
                    });
                  }
                },
                onPanUpdate: (details) {
                  if (isResizing && selectedIndex != null) {
                    _resizeBox(selectedIndex!, details.delta);
                  }
                  else if (selectedIndex != null && startDrag != null) {
                    _updateBoxPosition(selectedIndex!, details.delta);
                  }
                  setState(() {
                    currentDrag = details.localPosition;
                  });
                },
                onPanEnd: (_) {
                  if (startDrag != null && currentDrag != null && selectedIndex == null) {
                    final rect = Rect.fromPoints(startDrag!, currentDrag!);
                    final double minWidth = 10;
                    final double minHeight = 10;
                    if (rect.width >= minWidth && rect.height >= minHeight) {
                      _addNewBox(rect);
                    }
                  }
                  setState(() {
                    startDrag = null;
                    currentDrag = null;
                    isResizing = false;
                  });
                },
                child: Stack(
                  children: [
                    Image.memory(
                      widget.imageBytes,
                      width: screenSize.width,
                      height: screenSize.height,
                      fit: BoxFit.cover,
                    ),
                    ...boxes.asMap().entries.map((entry) {
                      int i = entry.key;
                      final box = entry.value['box'];
                      final double left = box[0];
                      final double top = box[1];
                      final double width = box[2] - box[0];
                      final double height = box[3] - box[1];

                      return Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = i;
                            });
                          },
                          onDoubleTap: _showLabelDialog,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedIndex == i ? Colors.blue : Colors.red,
                                    width: selectedIndex == i ? 3 : 2,
                                  ),
                                  color: selectedIndex == i
                                      ? Colors.blue.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.1),
                                ),
                                alignment: Alignment.topLeft,
                                child: GestureDetector(
                                  onTap: _showLabelDialog,
                                  child: Container(
                                    color: selectedIndex == i ? Colors.blue : Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      entry.value['label'] ?? 'Unknown',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedIndex == i)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  width: 16,
                                  height: 16,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (startDrag != null && currentDrag != null && selectedIndex == null)
                      Positioned(
                        left: (startDrag!.dx < currentDrag!.dx)
                            ? startDrag!.dx
                            : currentDrag!.dx,
                        top: (startDrag!.dy < currentDrag!.dy)
                            ? startDrag!.dy
                            : currentDrag!.dy,
                        width: (startDrag!.dx - currentDrag!.dx).abs(),
                        height: (startDrag!.dy - currentDrag!.dy).abs(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomDrawer(),
          ),
        ],
      ),
    );
  }
}