import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: user == null
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.errorMessage.isNotEmpty
                    ? auth.errorMessage
                    : 'Profile is not available right now.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().loadProfile(),
                child: const Text('Retry'),
              ),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage:
                user.image != null ? NetworkImage(user.image!) : null,
                child: user.image == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('@${user.username}'),
              if (user.email != null) Text(user.email!),
              if (user.gender != null) Text(user.gender!),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}