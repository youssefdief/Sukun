class DhikrItem {
  final String text;
  final String translation;
  final int count;

  DhikrItem({
    required this.text,
    required this.translation,
    required this.count,
  });
}

class DhikrService {
  String getCurrentDhikrType(DateTime now) {
    int hour = now.hour;
    if (hour >= 4 && hour < 11) {
      return 'Morning';
    } else if (hour >= 11 && hour < 17) {
      return 'General';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  List<DhikrItem> getDhikrList(String type) {
    switch (type) {
      case 'Morning':
        return [
          DhikrItem(
            text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
            translation: "We have entered a new day and with it all dominion is Allah's",
            count: 1,
          ),
          DhikrItem(
            text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا',
            translation: 'O Allah, by You we enter the morning and by You we enter the evening',
            count: 1,
          ),
          DhikrItem(
            text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
            translation: 'Glory is to Allah and praise is to Him',
            count: 100,
          ),
        ];
      case 'Evening':
        return [
          DhikrItem(
            text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
            translation: "We have entered the evening and with it all dominion is Allah's",
            count: 1,
          ),
          DhikrItem(
            text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا',
            translation: 'O Allah, by You we enter the evening and by You we enter the morning',
            count: 1,
          ),
          DhikrItem(
            text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
            translation: 'I seek refuge in the Perfect Words of Allah from the evil of what He has created',
            count: 3,
          ),
        ];
      case 'Night':
        return [
          DhikrItem(
            text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
            translation: 'In Your name, O Allah, I die and I live',
            count: 1,
          ),
          DhikrItem(
            text: 'سُبْحَانَ اللَّهِ',
            translation: 'Glory is to Allah',
            count: 33,
          ),
          DhikrItem(
            text: 'الْحَمْدُ لِلَّهِ',
            translation: 'Praise is to Allah',
            count: 33,
          ),
          DhikrItem(
            text: 'اللَّهُ أَكْبَرُ',
            translation: 'Allah is Most Great',
            count: 34,
          ),
        ];
      case 'General':
      default:
        return [
          DhikrItem(
            text: 'سُبْحَانَ اللهِ',
            translation: 'Glory is to Allah',
            count: 100,
          ),
          DhikrItem(
            text: 'الْحَمْدُ لِلَّهِ',
            translation: 'Praise is to Allah',
            count: 100,
          ),
          DhikrItem(
            text: 'لَا إِلَهَ إِلَّا اللَّهُ',
            translation: 'There is no deity but Allah',
            count: 100,
          ),
          DhikrItem(
            text: 'اللَّهُ أَكْبَرُ',
            translation: 'Allah is Most Great',
            count: 100,
          ),
        ];
    }
  }
}
