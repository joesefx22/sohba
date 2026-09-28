import 'package:flutter/material.dart';
import '../services/background_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = BackgroundService().currentBackground;
  }

  @override
  Widget build(BuildContext context) {
    final backgrounds = BackgroundService().availableBackgrounds;

    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('Erscheinungsbild'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hintergrund',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Wähle ein Hintergrundbild für die App',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: backgrounds.length,
                        itemBuilder: (context, index) {
                          final bg = backgrounds[index];
                          final isSelected = bg == _selected;
                          return GestureDetector(
                            onTap: () => _selectBackground(bg),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : Colors.white.withAlpha(26),
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    isSelected ? 9 : 11),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(bg, fit: BoxFit.cover),
                                    if (isSelected)
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: AppColors.gold,
                                          size: 22,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBackground(String path) async {
    setState(() => _selected = path);
    await BackgroundService().setBackground(path);
  }
}
