import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import 'package:moto_comm_app_1/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/about/bike_card_widget.dart';
import 'package:provider/provider.dart';

class MyGaragePage extends StatefulWidget {
  const MyGaragePage({super.key});

  @override
  State<MyGaragePage> createState() => _MyGaragePageState();
}

class _MyGaragePageState extends State<MyGaragePage> {
  bool _isAddingNew = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında verileri tazeleyelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadMotorcycles();
    });
  }

  void _addNewBike() {
    setState(() {
      _isAddingNew = true;
    });
  }

  void _cancelAddNew() {
    setState(() {
      _isAddingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppFrostedButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text("Garajım", style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.motorcycles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final bikes = provider.motorcycles;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (bikes.isEmpty && !_isAddingNew)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "Henüz motor eklenmemiş.",
                        style: AppTextStyles.medium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                // Mevcut Motorlar
                ...bikes.map((bike) {
                  return BikeCardWidget(
                    key: ValueKey(bike.id ?? bike.hashCode),
                    bike: bike,
                    // Silme işlemi BikeCard içinde yönetiliyor (provider çağırarak)
                    // Ancak burada da ekstradan bir şey yapmak istersek parametresini kullanırız
                  );
                }),

                // Yeni Ekleme Kartı
                if (_isAddingNew)
                  BikeCardWidget(
                    key: const ValueKey("new_bike_garage"),
                    bike: const MotorcycleEntity(brand: "", model: ""),
                    initialEdit: true,
                    onDelete: _cancelAddNew,
                    onSave: _cancelAddNew,
                  ),

                const SizedBox(height: 20),

                // Ekle Butonu (Eğer şu an ekleme modunda değilsek göster)
                if (!_isAddingNew)
                  SizedBox(
                    width: 160,
                    child: ElevatedButton.icon(
                      onPressed: _addNewBike,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Motor Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // Alt boşluk
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
