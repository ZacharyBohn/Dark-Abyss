import 'package:flutter/material.dart';

import '../economy/currency_manager.dart';
import '../hub/vendor.dart';
import '../upgrades/upgrade.dart';
import '../upgrades/upgrade_manager.dart';
import 'menu_system.dart';

class UpgradeMenuRenderer {
  void render(
    Canvas canvas,
    Size size,
    MenuState menu,
    UpgradeManager upgradeManager,
    CurrencyManager currency,
  ) {
    // Dark overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.75),
    );

    // Menu panel
    final panelWidth = 500.0;
    final panelHeight = 400.0;
    final panelX = (size.width - panelWidth) / 2;
    final panelY = (size.height - panelHeight) / 2;

    // Panel background
    final panelRect = Rect.fromLTWH(panelX, panelY, panelWidth, panelHeight);
    canvas.drawRect(
      panelRect,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Panel border
    final borderColor = _vendorColor(menu.vendorType);
    canvas.drawRect(
      panelRect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Panel glow
    canvas.drawRect(
      panelRect.inflate(4),
      Paint()
        ..color = borderColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Title
    final title = _vendorTitle(menu.vendorType);
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: borderColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(panelX + (panelWidth - titlePainter.width) / 2, panelY + 15),
    );

    // Separator line
    canvas.drawLine(
      Offset(panelX + 20, panelY + 50),
      Offset(panelX + panelWidth - 20, panelY + 50),
      Paint()
        ..color = borderColor.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Upgrade rows
    final rowHeight = 50.0;
    final startY = panelY + 60;

    for (int i = 0; i < menu.upgrades.length; i++) {
      final upgrade = menu.upgrades[i];
      final isSelected = i == menu.selectedIndex;
      final currentTier = upgradeManager.getTier(upgrade.id);
      final isMaxed = upgradeManager.isMaxed(upgrade);
      final cost = upgradeManager.getNextCost(upgrade);
      final canAfford = upgradeManager.canPurchase(upgrade, currency);
      final isSpell = upgrade.category == UpgradeCategory.spell;

      final rowY = startY + i * rowHeight;

      // Selection highlight
      if (isSelected) {
        canvas.drawRect(
          Rect.fromLTWH(panelX + 10, rowY, panelWidth - 20, rowHeight - 4),
          Paint()..color = borderColor.withValues(alpha: 0.15),
        );
        // Selection indicator
        canvas.drawRect(
          Rect.fromLTWH(panelX + 10, rowY, 3, rowHeight - 4),
          Paint()..color = borderColor,
        );
      }

      // Upgrade name
      final nameColor = isSpell
          ? Colors.white38
          : isMaxed
              ? const Color(0xFF88FF88)
              : Colors.white;
      final namePainter = TextPainter(
        text: TextSpan(
          text: upgrade.name,
          style: TextStyle(
            color: nameColor,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(canvas, Offset(panelX + 25, rowY + 5));

      // Description
      final descPainter = TextPainter(
        text: TextSpan(
          text: upgrade.description,
          style: TextStyle(
            color: isSpell ? Colors.white24 : Colors.white54,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      descPainter.layout();
      descPainter.paint(canvas, Offset(panelX + 25, rowY + 26));

      // Tier pips (right side)
      if (!isSpell) {
        final pipStartX = panelX + panelWidth - 180;
        for (int t = 0; t < upgrade.maxTier; t++) {
          final pipX = pipStartX + t * 14.0;
          final isFilled = t < currentTier;
          canvas.drawRect(
            Rect.fromLTWH(pipX, rowY + 10, 10, 10),
            Paint()
              ..color = isFilled ? borderColor : Colors.white24
              ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }

      // Cost / status (far right)
      final String statusText;
      final Color statusColor;
      if (isSpell) {
        statusText = 'LOCKED';
        statusColor = Colors.white30;
      } else if (isMaxed) {
        statusText = 'MAX';
        statusColor = const Color(0xFF88FF88);
      } else if (cost != null) {
        final parts = <String>[];
        if (cost.gold > 0) parts.add('${cost.gold}g');
        if (cost.essence > 0) parts.add('${cost.essence}e');
        statusText = parts.join(' + ');
        statusColor = canAfford ? const Color(0xFFFFDD00) : const Color(0xFFFF4444);
      } else {
        statusText = '';
        statusColor = Colors.white;
      }

      final statusPainter = TextPainter(
        text: TextSpan(
          text: statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      statusPainter.layout();
      statusPainter.paint(
        canvas,
        Offset(panelX + panelWidth - statusPainter.width - 20, rowY + 25),
      );
    }

    // Bottom currency display
    final bottomY = panelY + panelHeight - 40;
    canvas.drawLine(
      Offset(panelX + 20, bottomY - 5),
      Offset(panelX + panelWidth - 20, bottomY - 5),
      Paint()
        ..color = borderColor.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Gold
    final goldPainter = TextPainter(
      text: TextSpan(
        text: 'Gold: ${currency.gold}',
        style: const TextStyle(
          color: Color(0xFFFFDD00),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    goldPainter.layout();
    goldPainter.paint(canvas, Offset(panelX + 25, bottomY + 5));

    // Essence
    final essencePainter = TextPainter(
      text: TextSpan(
        text: 'Essence: ${currency.essence}',
        style: const TextStyle(
          color: Color(0xFFAA00FF),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    essencePainter.layout();
    essencePainter.paint(canvas, Offset(panelX + 160, bottomY + 5));

    // Controls hint
    final controlsPainter = TextPainter(
      text: const TextSpan(
        text: 'W/S: Navigate | E: Buy | Esc: Close',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    controlsPainter.layout();
    controlsPainter.paint(
      canvas,
      Offset(panelX + panelWidth - controlsPainter.width - 20, bottomY + 7),
    );
  }

  Color _vendorColor(VendorType type) {
    switch (type) {
      case VendorType.stat:
        return const Color(0xFFFFDD00);
      case VendorType.ability:
        return const Color(0xFFAA00FF);
      case VendorType.spell:
        return const Color(0xFF00AAFF);
    }
  }

  String _vendorTitle(VendorType type) {
    switch (type) {
      case VendorType.stat:
        return 'STAT UPGRADES';
      case VendorType.ability:
        return 'ABILITIES';
      case VendorType.spell:
        return 'SPELLS';
    }
  }
}
