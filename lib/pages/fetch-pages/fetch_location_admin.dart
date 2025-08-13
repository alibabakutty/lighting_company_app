import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/config/maps_config.dart';
import 'package:lighting_company_app/service/location_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class FetchLocationAdmin extends StatefulWidget {
  const FetchLocationAdmin({super.key});

  @override
  State<FetchLocationAdmin> createState() => _FetchLocationAdminState();
}

class _FetchLocationAdminState extends State<FetchLocationAdmin> {
  List<AuthUser> _admins = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final admins = await authProvider.getAllAdmins();
      setState(() {
        _admins = admins;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openMap(GeoPoint location) async {
    final lat = location.latitude;
    final lng = location.longitude;

    // Try different URL schemes in order of preference
    final urls = [
      'comgooglemaps://?q=$lat,$lng', // Native Google Maps app
      'geo:$lat,$lng?q=$lat,$lng', // Generic geo URI (opens default map app)
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng', // Web fallback
    ];

    try {
      for (final url in urls) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          return; // Exit if successful
        }
      }
      // If all URLs failed
      throw 'No map application available';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: ${e.toString()}')),
      );
    }
  }

  Widget _locationPreview(GeoPoint location) {
    final staticMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap?'
        'center=${location.latitude},${location.longitude}'
        '&zoom=15'
        '&size=300x150'
        '&maptype=roadmap'
        '&markers=color:red%7C${location.latitude},${location.longitude}'
        '&key=${MapsConfig.apiKey}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FutureBuilder<bool>(
            future: _checkMapAvailability(staticMapUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == true) {
                return Image.network(
                  staticMapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Map load error: $error');
                    return _buildMapErrorState(location);
                  },
                );
              } else {
                return _buildMapErrorState(location);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildAddressText(location),
      ],
    );
  }

  Future<bool> _checkMapAvailability(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Map availability check failed: $e');
      return false;
    }
  }

  Widget _buildMapErrorState(GeoPoint location) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 30, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12),
            ),
            TextButton(
              onPressed: () => _openMap(location),
              child: const Text('Open in Maps'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressText(GeoPoint location) {
    return FutureBuilder<String>(
      future: LocationService.getAddressFromPosition(
        Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              ),
              SizedBox(width: 8),
              Text('Loading address...'),
            ],
          );
        }

        final text =
            snapshot.data ??
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

        return InkWell(
          onTap: () => _openMap(location),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admins Locations'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAdmins),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _admins.isEmpty
          ? const Center(child: Text('No admins found'))
          : ListView.builder(
              itemCount: _admins.length,
              itemBuilder: (context, index) {
                final admin = _admins[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: Text(admin.username ?? 'No username'),
                          subtitle: Text(admin.email ?? 'No email'),
                        ),
                        if (admin.lastLoginLocation != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _locationPreview(admin.lastLoginLocation!),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
