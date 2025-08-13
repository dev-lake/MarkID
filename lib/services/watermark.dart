import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Watermark {
  /// 通过[Uint8List]获取图片
  static Future<ui.Image> loadImageByUint8List(Uint8List list) async {
    ui.Codec codec = await ui.instantiateImageCodec(list);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  /// 图片加文字
  static imageAddWaterMarkType1(Uint8List imagelist, String textStr) async {
    int width, height;

    // 创建画布和图片
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(recorder);

    // 加载图片对象
    ui.Image image = await loadImageByUint8List(imagelist);
    width = image.width;
    height = image.height;

    // 计算对角线长度
    double dimension = math.sqrt(
      math.pow(image.width, 2) + math.pow(image.height, 2),
    );

    // 绘制原始图片到画布上
    canvas.drawImage(image, const Offset(0, 0), Paint());

    // 准备水印文本
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Paint()..blendMode = BlendMode.multiply,
    );
    var text = textStr;

    // 计算水印文本重复次数
    var rectSize = math.pow(dimension, 2);
    int textRepeating = ((rectSize / math.pow(30, 2) * 2) / (text.length + 8))
        .round();

    // 设置水印文本位置和样式
    math.Point pivotPoint = math.Point(dimension / 2, dimension / 2);
    canvas.translate(pivotPoint.x.toDouble(), pivotPoint.y.toDouble());
    canvas.rotate(-25 * math.pi / 180);
    canvas.translate(
      -pivotPoint.distanceTo(math.Point(0, image.height)),
      -pivotPoint.distanceTo(const math.Point(0, 0)),
    );

    var textPainter = TextPainter(
      text: TextSpan(
        text: (text.padRight(text.length + 8)) * textRepeating,
        style: const TextStyle(
          fontSize: 30,
          color: Color.fromRGBO(0, 0, 0, .3),
          height: 2,
        ),
      ),
      maxLines: null,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.start,
    );
    textPainter.layout(maxWidth: dimension);
    textPainter.paint(canvas, Offset.zero);

    canvas.restore();

    // 获取处理后的图片
    ui.Picture picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());

    // 转换为 Uint8List
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static Future<Uint8List?> imageAddWaterMarkType2(
    Uint8List imagelist,
    String textStr, {
    int rows = 4,
    int columns = 2,
    double angle = 45,
    double opacity = 0.1,
    int blockRows = 31,
    int blockColumns = 31,
  }) async {
    try {
      int width, height;

      // 拿到Canvas
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      // 拿到Image对象
      ui.Image image = await loadImageByUint8List(imagelist);
      width = image.width;
      height = image.height;

      // 绘制原始图片到Canvas
      canvas.drawImage(image, const Offset(0, 0), Paint());

      // 计算单位宽高
      final double unitWidth = width / blockColumns;
      final double unitHeight = height / blockRows;

      // 定义颜色渐变
      List<Color> colors = [
        Colors.blue.withOpacity(opacity),
        Colors.red.withOpacity(opacity),
        Colors.green.withOpacity(opacity),
        Colors.orange.withOpacity(opacity),
        Colors.purple.withOpacity(opacity),
      ];

      // 文本样式
      final textStyle = TextStyle(fontSize: width / 20);

      final textSpan = TextSpan(text: textStr, style: textStyle);

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final double stepX = width / (columns + 1);
      final double stepY = height / (rows + 1);

      for (int row = 1; row <= rows; row++) {
        for (int col = 1; col <= columns; col++) {
          final dx = col * stepX;
          final dy = row * stepY;
          final offset = Offset(dx, dy);
          canvas.save();
          canvas.translate(offset.dx, offset.dy);

          // 创建线性渐变
          final gradient = LinearGradient(colors: colors);

          final Paint paint = Paint()
            ..shader = gradient.createShader(
              Rect.fromLTWH(
                -textPainter.width / 2,
                -textPainter.height / 2,
                textPainter.width,
                textPainter.height,
              ),
            );

          final textStyleWithGradient = textStyle.copyWith(foreground: paint);
          final textSpanWithGradient = TextSpan(
            text: textStr,
            style: textStyleWithGradient,
          );

          final textPainterWithGradient = TextPainter(
            text: textSpanWithGradient,
            textDirection: TextDirection.ltr,
          );

          textPainterWithGradient.layout();

          // 应用旋转
          canvas.rotate(angle * math.pi / 180);
          textPainterWithGradient.paint(
            canvas,
            Offset(
              -textPainterWithGradient.width / 2,
              -textPainterWithGradient.height / 2,
            ),
          );
          canvas.restore();
        }
      }

      // 结束绘制
      ui.Picture picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());

      // 转换为 Uint8List
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return pngBytes!.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
