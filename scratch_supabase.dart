import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://llcbdjidwudzwtgiplzf.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsY2Jkamlkd3Vkend0Z2lwbHpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MTk1NTMsImV4cCI6MjA4NjI5NTU1M30.ms12T7mCjB98qHd-36AiP-biQZ_9Sxcg0jlvUNJZQdM';

  final supabase = SupabaseClient(url, anonKey);

  try {
    print('Fetching customers...');
    final response = await supabase.from('customers').select();
    print('Customers: $response');
  } catch (e) {
    print('Error: $e');
  }
}
