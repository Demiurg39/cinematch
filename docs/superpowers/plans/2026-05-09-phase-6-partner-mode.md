# Cinematch Phase 6: Partner Mode

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow two users to pair up and swipe together. Shared swipe session with real-time sync. Partner link via code/invite.

**Architecture:** Partner pairs stored in `partners` table. Shared room for synced swiping. Supabase Realtime for partner actions.

**Tech Stack:** flutter_riverpod, Supabase Realtime, Supabase Postgres

---

## File Structure

```
lib/features/partners/
├── domain/
│   └── partner_model.dart          # Partner relationship model
├── data/
│   └── partners_repository.dart    # Partner CRUD
└── presentation/
    ├── partners_screen.dart         # Partner list/management
    ├── add_partner_screen.dart      # Add via code
    └── providers/
        ├── partners_provider.dart   # Partner list state
        └── active_partner_provider.dart # Active partner session
```

---

## Tasks

### Task 1: Partner Model

**Files:**
- Create: `lib/features/partners/domain/partner_model.dart`

- [ ] **Step 1: Create partner_model.dart**

```dart
enum PartnerStatus { pending, active, blocked }

class PartnerModel {
  final String id;
  final String partnerId;
  final String partnerUsername;
  final PartnerStatus status;
  final String? inviteCode;
  final DateTime createdAt;

  const PartnerModel({
    required this.id,
    required this.partnerId,
    required this.partnerUsername,
    required this.status,
    this.inviteCode,
    required this.createdAt,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      partnerUsername: json['partner_username'] as String? ?? 'Unknown',
      status: PartnerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartnerStatus.pending,
      ),
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'partner_id': partnerId,
        'partner_username': partnerUsername,
        'status': status.name,
        'invite_code': inviteCode,
        'created_at': createdAt.toIso8601String(),
      };
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/partners/domain/partner_model.dart && git commit -m "feat: add PartnerModel"
```

---

### Task 2: Partners Repository

**Files:**
- Create: `lib/features/partners/data/partners_repository.dart`

- [ ] **Step 1: Create partners_repository.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partner_model.dart';

class PartnersRepository {
  final SupabaseClient _client;
  PartnersRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<PartnerModel> sendPartnerRequest(String partnerUsername) async {
    final code = _generateInviteCode();
    final userId = currentUserId!;

    // Find partner by username
    final partner = await _client.from('users').select().eq('username', partnerUsername).maybeOne();
    if (partner == null) throw Exception('User not found');

    final response = await _client.from('partners').insert({
      'user_id': userId,
      'partner_id': partner['id'],
      'partner_username': partnerUsername,
      'status': 'pending',
      'invite_code': code,
    }).select().single();

    return PartnerModel.fromJson(response);
  }

  Future<void> acceptPartnerRequest(String partnerId) async {
    await _client.from('partners').update({'status': 'active'})
        .eq('partner_id', partnerId).eq('user_id', currentUserId);
  }

  Future<void> rejectPartnerRequest(String partnerId) async {
    await _client.from('partners').delete()
        .eq('partner_id', partnerId).eq('user_id', currentUserId);
  }

  Future<void> removePartner(String partnerId) async {
    await _client.from('partners').delete()
        .or('and(partner_id.eq.$partnerId,user_id.eq.${currentUserId}),and(user_id.eq.$partnerId,partner_id.eq.${currentUserId})');
  }

  Future<List<PartnerModel>> getPartners() async {
    final userId = currentUserId!;
    final response = await _client.from('partners').select()
        .or('user_id.eq.$userId,partner_id.eq.$userId');
    return response.map((json) => PartnerModel.fromJson(json)).toList();
  }

  Stream<List<PartnerModel>> watchPartners() {
    final userId = currentUserId!;
    return _client.from('partners').stream(primaryKey: ['id'])
        .or('user_id.eq.$userId,partner_id.eq.$userId')
        .map((data) => data.map((json) => PartnerModel.fromJson(json)).toList());
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(8, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/partners/data/partners_repository.dart && git commit -m "feat: add PartnersRepository"
```

---

### Task 3: Partners Providers

**Files:**
- Create: `lib/features/partners/presentation/providers/partners_provider.dart`
- Create: `lib/features/partners/presentation/providers/active_partner_provider.dart`

- [ ] **Step 1: Create partners_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/partners_repository.dart';
import '../../domain/partner_model.dart';

part 'partners_provider.g.dart';

@riverpod
PartnersRepository partnersRepository(PartnersRepositoryRef ref) {
  return PartnersRepository();
}

@riverpod
class PartnersNotifier extends _$PartnersNotifier {
  @override
  Stream<List<PartnerModel>> build() {
    return ref.read(partnersRepositoryProvider).watchPartners();
  }

  Future<void> sendRequest(String username) async {
    await ref.read(partnersRepositoryProvider).sendPartnerRequest(username);
  }

  Future<void> accept(String partnerId) async {
    await ref.read(partnersRepositoryProvider).acceptPartnerRequest(partnerId);
  }

  Future<void> reject(String partnerId) async {
    await ref.read(partnersRepositoryProvider).rejectPartnerRequest(partnerId);
  }

  Future<void> remove(String partnerId) async {
    await ref.read(partnersRepositoryProvider).removePartner(partnerId);
  }
}
```

- [ ] **Step 2: Create active_partner_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/partners_repository.dart';
import '../../domain/partner_model.dart';

part 'active_partner_provider.g.dart';

@riverpod
class ActivePartnerNotifier extends _$ActivePartnerNotifier {
  @override
  Future<PartnerModel?> build() async {
    final partners = await ref.read(partnersRepositoryProvider).getPartners();
    return partners.where((p) => p.status == PartnerStatus.active).firstOrNull;
  }

  Future<void> setActivePartner(PartnerModel partner) async {
    state = AsyncData(partner);
  }

  void clearActivePartner() {
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 3: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/features/partners/ && git commit -m "feat: add partners providers"
```

---

### Task 4: Partners Screens

**Files:**
- Create: `lib/features/partners/presentation/partners_screen.dart`
- Create: `lib/features/partners/presentation/add_partner_screen.dart`

- [ ] **Step 1: Create partners_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/partners_provider.dart';
import '../../domain/partner_model.dart';
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
```

- [ ] **Step 2: Create add_partner_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/partners_provider.dart';

class AddPartnerScreen extends ConsumerStatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  ConsumerState<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends ConsumerState<AddPartnerScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Partner Username',
                hintText: 'Enter their username',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(partnersNotifierProvider.notifier).sendRequest(_usernameController.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/partners/presentation/partners_screen.dart lib/features/partners/presentation/add_partner_screen.dart && git commit -m "feat: add PartnersScreen and AddPartnerScreen"
```

---

### Task 5: Partner Tests

**Files:**
- Create: `test/partners/partner_model_test.dart`

- [ ] **Step 1: Create partner_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/partners/domain/partner_model.dart';

void main() {
  group('PartnerModel', () {
    test('fromJson creates PartnerModel correctly', () {
      final json = {
        'id': 'partner-123',
        'partner_id': 'user-456',
        'partner_username': 'johndoe',
        'status': 'active',
        'invite_code': 'ABC12345',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json);

      expect(partner.id, 'partner-123');
      expect(partner.partnerId, 'user-456');
      expect(partner.partnerUsername, 'johndoe');
      expect(partner.status, PartnerStatus.active);
      expect(partner.inviteCode, 'ABC12345');
    });

    test('toJson creates correct map', () {
      final partner = PartnerModel(
        id: 'partner-123',
        partnerId: 'user-456',
        partnerUsername: 'johndoe',
        status: PartnerStatus.pending,
        inviteCode: 'XYZ98765',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = partner.toJson();

      expect(json['id'], 'partner-123');
      expect(json['partner_id'], 'user-456');
      expect(json['partner_username'], 'johndoe');
      expect(json['status'], 'pending');
    });
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add test/partners/partner_model_test.dart && git commit -m "test: add PartnerModel tests"
```

---

## Self-Review

- [x] PartnerModel with PartnerStatus enum
- [x] PartnersRepository with CRUD + Realtime watch
- [x] PartnersNotifier + ActivePartnerNotifier
- [x] PartnersScreen with partner list
- [x] AddPartnerScreen with username search
- [x] Tests for PartnerModel
- [ ] Next: Phase 7 Friends System

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-6-partner-mode.md`**
