import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/thermal_printer_service.dart';

class ThermalPrinterScreen extends StatefulWidget {
  const ThermalPrinterScreen({super.key});

  @override
  State<ThermalPrinterScreen> createState() => _ThermalPrinterScreenState();
}

class _ThermalPrinterScreenState extends State<ThermalPrinterScreen> {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkStatus();
  }

  Future<void> _loadDevices() async {
    final devices = await _printerService.getDevices();
    setState(() => _devices = devices);
  }

  Future<void> _checkStatus() async {
    final connected = await _printerService.isConnected();
    setState(() => _isConnected = connected == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thermal Printer', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isConnected
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error_outline,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isConnected ? 'Printer Connected' : 'Printer Disconnected',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _isConnected
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Select Paired Printer',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        device.name ?? 'Unknown Device',
                        style: GoogleFonts.poppins(),
                      ),
                      subtitle: Text(device.address ?? ''),
                      trailing: _selectedDevice?.address == device.address
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () => setState(() => _selectedDevice = device),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedDevice == null
                    ? null
                    : () async {
                        if (_isConnected) {
                          await _printerService.disconnect();
                        } else {
                          try {
                            await _printerService.connect(_selectedDevice!);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connection failed: $e')),
                            );
                          }
                        }
                        _checkStatus();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isConnected ? 'Disconnect' : 'Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
