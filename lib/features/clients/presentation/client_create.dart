// ─────────────────────────────────────────────────────────────────────────────
// lib/features/clients/presentation/client_create.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../data/models/client_model.dart';
import 'client_form_screen.dart';

class ClientCreate extends StatelessWidget {
  final ClientModel? client;

  const ClientCreate({super.key, this.client});

  @override
  Widget build(BuildContext context) {
    return ClientFormScreen(client: client);
  }
}
