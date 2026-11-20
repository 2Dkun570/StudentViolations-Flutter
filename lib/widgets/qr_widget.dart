import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Lightweight pure-Dart QR Code generator and renderer (ISO/IEC 18004 compatible).
/// Encodes strings in Byte mode with Error Correction Level M.
class QrCodeMatrix {
  final int version;
  final int size;
  final List<List<bool>> modules;

  QrCodeMatrix._(this.version, this.size, this.modules);

  /// Generates a QR matrix for the given text. Supports strings up to ~42 characters.
  factory QrCodeMatrix.encode(String text) {
    final bytes = utf8.encode(text);
    // Version 2 can hold up to 26 bytes with EC Level M (28 codewords)
    // Version 3 can hold up to 42 bytes with EC Level M (44 codewords)
    // Version 4 can hold up to 62 bytes with EC Level M (64 codewords)
    final int version;
    final int dataCodewords;
    final int ecCodewords;
    final List<int> alignmentPositions;

    if (bytes.length <= 26) {
      version = 2;
      dataCodewords = 28;
      ecCodewords = 16;
      alignmentPositions = [6, 18];
    } else if (bytes.length <= 42) {
      version = 3;
      dataCodewords = 44;
      ecCodewords = 26;
      alignmentPositions = [6, 22];
    } else {
      version = 4;
      dataCodewords = 64;
      ecCodewords = 36;
      alignmentPositions = [6, 26];
    }

    final size = 21 + 4 * (version - 1);
    final matrix = List.generate(size, (_) => List.filled(size, false));
    final isReserved = List.generate(size, (_) => List.filled(size, false));

    // 1. Pack data bits in Byte mode (0100)
    final bitBuffer = <int>[];
    // Mode indicator: 0100 (4 bits)
    _pushBits(bitBuffer, 4, 0x4);
    // Character count indicator: 8 bits for versions 1-9 in Byte mode
    _pushBits(bitBuffer, 8, bytes.length);
    // Data bytes
    for (final b in bytes) {
      _pushBits(bitBuffer, 8, b);
    }
    // Terminator: up to 4 bits of 0
    final maxDataBits = dataCodewords * 8;
    final termLen = (maxDataBits - bitBuffer.length).clamp(0, 4);
    _pushBits(bitBuffer, termLen, 0);

    // Pad to byte boundary
    while (bitBuffer.length % 8 != 0) {
      bitBuffer.add(0);
    }

    // Convert bits to byte codewords
    final data = <int>[];
    for (int i = 0; i < bitBuffer.length; i += 8) {
      int val = 0;
      for (int j = 0; j < 8; j++) {
        val = (val << 1) | bitBuffer[i + j];
      }
      data.add(val);
    }

    // Pad bytes alternating 0xEC and 0x11
    final padBytes = [0xEC, 0x11];
    int padIdx = 0;
    while (data.length < dataCodewords) {
      data.add(padBytes[padIdx]);
      padIdx = 1 - padIdx;
    }

    // 2. Compute Reed-Solomon Error Correction
    final ec = _computeReedSolomon(data, ecCodewords);
    final allCodewords = [...data, ...ec];

    // Convert all codewords to bit stream
    final allBits = <int>[];
    for (final cw in allCodewords) {
      for (int i = 7; i >= 0; i--) {
        allBits.add((cw >> i) & 1);
      }
    }

    // 3. Mark and draw function patterns
    // 3a. Finder patterns
    _drawFinderPattern(matrix, isReserved, 0, 0, size);
    _drawFinderPattern(matrix, isReserved, size - 7, 0, size);
    _drawFinderPattern(matrix, isReserved, 0, size - 7, size);

    // 3b. Separators
    _drawSeparators(matrix, isReserved, size);

    // 3c. Timing patterns
    for (int i = 8; i < size - 8; i++) {
      final bit = (i % 2 == 0);
      matrix[6][i] = bit;
      isReserved[6][i] = true;
      matrix[i][6] = bit;
      isReserved[i][6] = true;
    }

    // 3d. Alignment patterns (skip corners covered by finders)
    for (final r in alignmentPositions) {
      for (final c in alignmentPositions) {
        if (isReserved[r][c]) continue;
        _drawAlignmentPattern(matrix, isReserved, r, c);
      }
    }

    // 3e. Dark module
    matrix[size - 8][8] = true;
    isReserved[size - 8][8] = true;

    // 3f. Reserve format info areas
    _reserveFormatAreas(isReserved, size);

    // 4. Place data bits using zig-zag scanning
    int bitIndex = 0;
    int col = size - 1;
    bool goingUp = true;

    while (col > 0) {
      if (col == 6) col--; // Skip vertical timing pattern column

      final rows = goingUp
          ? List.generate(size, (i) => size - 1 - i)
          : List.generate(size, (i) => i);

      for (final row in rows) {
        for (int c = 0; c < 2; c++) {
          final currentCol = col - c;
          if (!isReserved[row][currentCol]) {
            int bit = 0;
            if (bitIndex < allBits.length) {
              bit = allBits[bitIndex++];
            }
            // Apply Mask 0: (row + col) % 2 == 0
            final mask = ((row + currentCol) % 2 == 0) ? 1 : 0;
            matrix[row][currentCol] = (bit ^ mask) == 1;
          }
        }
      }
      col -= 2;
      goingUp = !goingUp;
    }

    // 5. Draw Format Information (EC Level M = 00, Mask 0 = 000)
    // Precalculated 15-bit format for Level M and Mask 0: 0x5412 ^ 0x4849 = 0x1C5B
    // Format bits = 0x1C5B (binary: 001110001011011)
    const int formatBits = 0x1C5B;
    _drawFormatInfo(matrix, formatBits, size);

    return QrCodeMatrix._(version, size, matrix);
  }

  static void _pushBits(List<int> buffer, int bitCount, int value) {
    for (int i = bitCount - 1; i >= 0; i--) {
      buffer.add((value >> i) & 1);
    }
  }

  static void _drawFinderPattern(
    List<List<bool>> m,
    List<List<bool>> res,
    int r0,
    int c0,
    int size,
  ) {
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        final isBorder = (r == 0 || r == 6 || c == 0 || c == 6);
        final isCenter = (r >= 2 && r <= 4 && c >= 2 && c <= 4);
        m[r0 + r][c0 + c] = isBorder || isCenter;
        res[r0 + r][c0 + c] = true;
      }
    }
  }

  static void _drawSeparators(
    List<List<bool>> m,
    List<List<bool>> res,
    int size,
  ) {
    for (int i = 0; i < 8; i++) {
      // Top-left
      _setSep(m, res, 7, i);
      _setSep(m, res, i, 7);
      // Top-right
      _setSep(m, res, 7, size - 8 + i);
      _setSep(m, res, i, size - 8);
      // Bottom-left
      _setSep(m, res, size - 8, i);
      _setSep(m, res, size - 8 + i, 7);
    }
  }

  static void _setSep(List<List<bool>> m, List<List<bool>> res, int r, int c) {
    m[r][c] = false;
    res[r][c] = true;
  }

  static void _drawAlignmentPattern(
    List<List<bool>> m,
    List<List<bool>> res,
    int centerR,
    int centerC,
  ) {
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        final isOuter = (r.abs() == 2 || c.abs() == 2);
        final isCenter = (r == 0 && c == 0);
        m[centerR + r][centerC + c] = isOuter || isCenter;
        res[centerR + r][centerC + c] = true;
      }
    }
  }

  static void _reserveFormatAreas(List<List<bool>> res, int size) {
    for (int i = 0; i < 9; i++) {
      res[8][i] = true;
      res[i][8] = true;
    }
    for (int i = 0; i < 8; i++) {
      res[8][size - 1 - i] = true;
      res[size - 1 - i][8] = true;
    }
  }

  static void _drawFormatInfo(List<List<bool>> m, int formatBits, int size) {
    final bits = List.generate(15, (i) => (formatBits >> (14 - i)) & 1 == 1);

    // Top-left format placement
    final tlCoords = [
      [8, 0],
      [8, 1],
      [8, 2],
      [8, 3],
      [8, 4],
      [8, 5],
      [8, 7],
      [8, 8],
      [7, 8],
      [5, 8],
      [4, 8],
      [3, 8],
      [2, 8],
      [1, 8],
      [0, 8],
    ];
    for (int i = 0; i < 15; i++) {
      m[tlCoords[i][0]][tlCoords[i][1]] = bits[i];
    }

    // Split format placement (bottom-left and top-right)
    final splitCoords = [
      [size - 1, 8],
      [size - 2, 8],
      [size - 3, 8],
      [size - 4, 8],
      [size - 5, 8],
      [size - 6, 8],
      [size - 7, 8],
      [8, size - 8],
      [8, size - 7],
      [8, size - 6],
      [8, size - 5],
      [8, size - 4],
      [8, size - 3],
      [8, size - 2],
      [8, size - 1],
    ];
    for (int i = 0; i < 15; i++) {
      m[splitCoords[i][0]][splitCoords[i][1]] = bits[i];
    }
  }

  static List<int> _computeReedSolomon(List<int> data, int ecCount) {
    // Galois Field GF(256) tables with primitive polynomial 0x11D
    final exp = List<int>.filled(512, 0);
    final log = List<int>.filled(256, 0);
    int x = 1;
    for (int i = 0; i < 255; i++) {
      exp[i] = x;
      exp[i + 255] = x;
      log[x] = i;
      x = x << 1;
      if (x >= 256) x ^= 0x11D;
    }

    // Generator polynomial for ecCount
    var gen = [1];
    for (int i = 0; i < ecCount; i++) {
      final root = exp[i];
      final nextGen = List<int>.filled(gen.length + 1, 0);
      for (int j = 0; j < gen.length; j++) {
        nextGen[j] ^= exp[(log[gen[j]] + log[root]) % 255];
        nextGen[j + 1] ^= gen[j];
      }
      gen = nextGen;
    }

    // Polynomial division to find remainder
    final remainder = List<int>.filled(ecCount, 0);
    for (final byte in data) {
      final factor = byte ^ remainder[0];
      for (int j = 0; j < ecCount - 1; j++) {
        remainder[j] = remainder[j + 1];
      }
      remainder[ecCount - 1] = 0;

      if (factor != 0) {
        final logFactor = log[factor];
        for (int j = 0; j < ecCount; j++) {
          final term = gen[gen.length - 2 - j];
          remainder[j] ^= exp[(log[term] + logFactor) % 255];
        }
      }
    }

    return remainder;
  }
}

/// CustomPainter that renders a QR matrix onto a canvas with crisp pixel alignment.
class QrMatrixPainter extends CustomPainter {
  final QrCodeMatrix matrix;
  final Color darkColor;
  final Color lightColor;

  const QrMatrixPainter({
    required this.matrix,
    this.darkColor = const Color(0xFF1E1E1E),
    this.lightColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = lightColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final n = matrix.size;
    final cellSize = size.width / n;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix.modules[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * cellSize,
              r * cellSize,
              cellSize + 0.1,
              cellSize + 0.1,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrMatrixPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.darkColor != darkColor ||
        oldDelegate.lightColor != lightColor;
  }
}

/// Seamless QR Code presentation widget matching modern minimalist digital pass screens.
class MinimalQrCard extends StatelessWidget {
  final String data;
  final String? base64Image;
  final double size;
  final VoidCallback? onTap;

  const MinimalQrCard({
    super.key,
    required this.data,
    this.base64Image,
    this.size = 260,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget qrContent;

    if (base64Image != null && base64Image!.trim().isNotEmpty) {
      try {
        final cleanBase64 = base64Image!.replaceAll('\n', '').trim();
        final bytes = base64Decode(cleanBase64);
        qrContent = Image.memory(
          Uint8List.fromList(bytes),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackQr(),
        );
      } catch (_) {
        qrContent = _buildFallbackQr();
      }
    } else {
      qrContent = _buildFallbackQr();
    }

    final card = Container(
      width: size,
      height: size,
      color: Colors.white,
      child: qrContent,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }

  Widget _buildFallbackQr() {
    try {
      final matrix = QrCodeMatrix.encode(data.isNotEmpty ? data : 'DEMO-PASS');
      return CustomPaint(
        size: Size(size, size),
        painter: QrMatrixPainter(matrix: matrix),
      );
    } catch (_) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: const Icon(
          Icons.qr_code_2_rounded,
          size: 80,
          color: Color(0xFF1E1E1E),
        ),
      );
    }
  }
}
