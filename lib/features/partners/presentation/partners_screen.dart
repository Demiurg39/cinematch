import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/partners_provider.dart';
import '../domain/partner_model.dart';
import 'add_partner_screen.dart';

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partners')),
      body: partnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (partners) {
          if (partners.isEmpty) {
            return const Center(child: Text('No partners yet'));
          }
          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              return ListTile(
                leading: CircleAvatar(child: Text(partner.partnerUsername[0].toUpperCase())),
                title: Text(partner.partnerUsername),
                subtitle: Chip(label: Text(partner.status.name)),
                trailing: partner.status == PartnerStatus.active
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {},
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
