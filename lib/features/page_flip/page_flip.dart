import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class PageFlipWidget extends StatefulWidget {
  const PageFlipWidget({
    Key? key,
    this.duration = const Duration(milliseconds: 450),
    this.cutoffForward = 0.8,
    this.cutoffPrevious = 0.1,
    this.backgroundColor = Colors.white,
    required this.children,
    this.initialIndex = 0,
    this.onPageChanged,
    this.onLastPageExit,
  }) : super(key: key);

  final Color backgroundColor;
  final List<Widget> children;
  final Duration duration;
  final int initialIndex;
  final double cutoffForward;
  final double cutoffPrevious;
  final void Function(int pageNumber)? onPageChanged;
  final VoidCallback? onLastPageExit;

  @override
  PageFlipWidgetState createState() => PageFlipWidgetState();
}

class PageFlipWidgetState extends State<PageFlipWidget>
    with TickerProviderStateMixin {
  List<Widget> pages = [];
  final List<AnimationController> _controllers = [];
  bool? _isForward;

  @override
  void didUpdateWidget(PageFlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    imageData = {};
    currentPageIndex = ValueNotifier(widget.initialIndex);
    _refreshPages();
    // debugPrint("no of pages are ${widget.children.length}");
  }

  void _refreshPages() {
    _controllers.clear();
    pages.clear();
    if (currentPageIndex.value > 0) {
      final controller = AnimationController(
        value: 0,
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(controller);
      final child = PageFlipBuilder(
        amount: controller,
        backgroundColor: widget.backgroundColor,
        pageIndex: currentPageIndex.value - 1,
        key: Key('${currentPageIndex.value - 1}'),
        child: widget.children[currentPageIndex.value - 1],
      );
      pages.add(child);
    }
    for (var i = 0;
        i < math.min(widget.children.length - currentPageIndex.value, 2);
        i++) {
      final controller = AnimationController(
        value: 1,
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(controller);
      final child = PageFlipBuilder(
        amount: controller,
        backgroundColor: widget.backgroundColor,
        pageIndex: currentPageIndex.value + i,
        key: Key('${currentPageIndex.value + i}'),
        child: widget.children[currentPageIndex.value + i],
      );
      pages.add(child);
    }
    setState(() {
      pages = pages.reversed.toList();
    });
  }

  bool get _isLastPage =>
      (widget.children.length - 1) == currentPageIndex.value;

  bool get _isFirstPage => currentPageIndex.value == 0;

  int get currPageTurnIndex => currentPageIndex.value != 0 ? 1 : 0;
  int get prevPageTurnIndex => 0;

  void _turnPage(DragUpdateDetails details, BoxConstraints dimens) {
    final ratio = details.delta.dx / dimens.maxWidth;
    if (_isForward == null) {
      if (details.delta.dx > 0.0) {
        _isForward = false;
      } else if (details.delta.dx < -0.2) {
        _isForward = true;
      } else {
        _isForward = null;
      }
    }
    if (_isForward == true || currentPageIndex.value == 0) {
      if (!_isLastPage) {
        _controllers[currPageTurnIndex].value += ratio;
      }
    }
  }

  Future _onDragFinish() async {
    if (_isForward != null) {
      if (_isForward == true) {
        if (_controllers[currPageTurnIndex].value <=
            (widget.cutoffForward + 0.15)) {
          await nextPage();
        } else {
          if (!_isLastPage) {
            await _controllers[currPageTurnIndex].forward();
          }
        }
      } else {
        if (!_isFirstPage &&
            _controllers[prevPageTurnIndex].value >= widget.cutoffPrevious) {
          await previousPage();
        } else {
          if (_isFirstPage) {
            await _controllers[currPageTurnIndex].forward();
          } else {
            await _controllers[prevPageTurnIndex].reverse();
            if (!_isFirstPage) {
              await previousPage();
            }
          }
        }
      }
    }

    _isForward = null;
  }

  Future nextPage() async {
    await _controllers[currPageTurnIndex].reverse();
    if (mounted) {
      widget.onPageChanged?.call(currentPageIndex.value + 1);
    }
    currentPageIndex.value = currentPageIndex.value + 1;

    if (_isLastPage) {
      widget.onLastPageExit?.call();
    }

    _refreshPages();
  }

  Future previousPage() async {
    await _controllers[prevPageTurnIndex].forward();
    if (mounted) {
      widget.onPageChanged?.call(currentPageIndex.value - 1);
    }
    currentPageIndex.value = currentPageIndex.value - 1;
    imageData[currentPageIndex.value] = null;

    _refreshPages();
  }

  // Future goToPage(int index) async {
  //   if (mounted) {
  //     widget.onPageChanged?.call(index);
  //   }
  //   for (var i = 0; i < _controllers.length; i++) {
  //     if (i == index) {
  //       _controllers[i].forward();
  //     } else if (i < index) {
  //       _controllers[i].reverse();
  //     } else {
  //       if (_controllers[i].status == AnimationStatus.reverse) {
  //         _controllers[i].value = 1;
  //       }
  //     }
  //   }
  //   currentPageIndex.value = index;
  // }

  @override
  Widget build(BuildContext context) {
    if (widget.initialIndex >= widget.children.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, dimens) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {},
        onTapUp: (details) {},
        onPanDown: (details) {},
        onPanEnd: (details) {},
        onTapCancel: () {},
        onHorizontalDragCancel: () => _isForward = null,
        onHorizontalDragUpdate: (details) => _turnPage(details, dimens),
        onHorizontalDragEnd: (details) => _onDragFinish(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (pages.isNotEmpty) ...pages else ...[const SizedBox.shrink()],
          ],
        ),
      ),
    );
  }
}

Map<int, ui.Image?> imageData = {};
ValueNotifier<int> currentPageIndex = ValueNotifier(0);

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    Key? key,
    required this.amount,
    this.backgroundColor,
    required this.child,
    required this.pageIndex,
  }) : super(key: key);

  final Animation<double> amount;
  final int pageIndex;
  final Color? backgroundColor;
  final Widget child;

  @override
  State<PageFlipBuilder> createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder> {
  final _boundaryKey = GlobalKey();

  void _captureImage(Duration timeStamp, int index) async {
    if (_boundaryKey.currentContext == null) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      if (_boundaryKey.currentContext == null ||
          _boundaryKey.currentContext!.findRenderObject() == null) {
        return;
      }
      final boundary = _boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.1);
      setState(() {
        imageData[index] = image.clone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentPageIndex,
      builder: (context, value, child) {
        if (imageData[widget.pageIndex] != null && value >= 0) {
          return CustomPaint(
            isComplex: true,
            painter: PageFlipEffect(
              amount: widget.amount,
              image: imageData[widget.pageIndex]!,
              backgroundColor: widget.backgroundColor,
            ),
            size: Size.infinite,
          );
        } else {
          if (value == widget.pageIndex || (value == (widget.pageIndex + 1))) {
            WidgetsBinding.instance.addPostFrameCallback(
              (timeStamp) => _captureImage(timeStamp, currentPageIndex.value),
            );
          }
          if (widget.pageIndex == currentPageIndex.value ||
              (widget.pageIndex == (currentPageIndex.value + 1))) {
            return ColoredBox(
              color: widget.backgroundColor ?? Colors.black12,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: widget.child,
              ),
            );
          } else {
            return Container();
          }
        }
      },
    );
  }
}

class PageFlipEffect extends CustomPainter {
  PageFlipEffect({
    required this.amount,
    required this.image,
    this.backgroundColor,
    this.radius = 0.18,
  }) : super(repaint: amount);

  final Animation<double> amount;
  final ui.Image image;
  final Color? backgroundColor;
  final double radius;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final double pos = amount.value;
    final double movX = (1.0 - pos);

    final double enhancedRadius = (radius * movX * 2).clamp(0.0, 0.05);
    final double wHRatio = 1 - enhancedRadius;
    final double hWRatio = image.height / image.width;

    final double screenWidth = size.width.toDouble();
    final double screenHeight = size.height.toDouble();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight));

    final double shadowXf = (wHRatio - movX);
    final double shadowSigma =
        Shadow.convertRadiusToSigma(8.0 + (32.0 * (1.0 - shadowXf)));

    final Rect pageRect =
        Rect.fromLTRB(0.0, 0.0, screenWidth * shadowXf, screenHeight);
    canvas.drawRect(pageRect, Paint()..color = backgroundColor!);

    if (pos != 0) {
      canvas.drawRect(
        pageRect,
        Paint()
          ..color = Colors.black54
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
      );
    }

    const double sliceWidth = 4.0;
    final Paint ip = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    final double scaleFactor = screenWidth / image.width;

    for (double x = 0; x < size.width; x += sliceWidth) {
      final double xWidthRatio = (x / screenWidth);
      final double curveValue = math.cos(math.pi / 0.7 * (xWidthRatio - movX));
      final double widthFactor = (xWidthRatio * wHRatio) - movX;
      final double heightFactor =
          (((screenHeight * enhancedRadius * movX) * hWRatio)) * curveValue;

      final double sourceX = x / scaleFactor;
      final double sourceWidth = sliceWidth / scaleFactor;

      final Rect source = Rect.fromLTRB(
          sourceX,
          0.0,
          math.min(sourceX + sourceWidth, image.width.toDouble()),
          image.height.toDouble());

      final Rect destination = Rect.fromLTRB(
        widthFactor * screenWidth,
        0.0 - heightFactor,
        (widthFactor * screenWidth) + sliceWidth,
        screenHeight + heightFactor,
      );

      canvas.drawImageRect(image, source, destination, ip);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(PageFlipEffect oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.amount.value != amount.value;
  }
}
