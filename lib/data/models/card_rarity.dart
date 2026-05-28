import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CardRarity {
  r('R'),
  sr('SR'),
  ssr('SSR'),
  ur('UR');

  final String code;
  const CardRarity(this.code);

  static CardRarity parse(String code) {
    return CardRarity.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CardRarity.r,
    );
  }

  Color get color => switch (this) {
        CardRarity.r => AppColors.rarityR,
        CardRarity.sr => AppColors.raritySR,
        CardRarity.ssr => AppColors.raritySSR,
        CardRarity.ur => AppColors.rarityUR,
      };

  int get score => switch (this) {
        CardRarity.r => 10,
        CardRarity.sr => 30,
        CardRarity.ssr => 80,
        CardRarity.ur => 200,
      };
}

enum CardExecutor {
  loser,
  winner,
  both;

  static CardExecutor parse(String value) {
    return CardExecutor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CardExecutor.loser,
    );
  }
}
