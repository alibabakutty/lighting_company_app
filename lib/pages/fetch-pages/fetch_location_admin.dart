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
        '&size=200x100'
        '&maptype=roadmap'
        '&markers=color:red%7C${location.latitude},${location.longitude}'
        '&key=${MapsConfig.apiKey}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.hardEdge,
          child: FutureBuilder<bool>(
            future: _checkMapAvailability(staticMapUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
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
        const SizedBox(height: 6),
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
            const Icon(Icons.location_on, size: 24, color: Colors.green),
            const SizedBox(height: 4),
            Text(
              '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            IconButton(
              onPressed: () => _openMap(location),
              icon: const Icon(Icons.map, size: 18, color: Colors.blue),
              tooltip: 'Open in Maps',
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
          return const Text(
            'Loading address...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          );
        }

        final text =
            snapshot.data ??
            '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';

        return InkWell(
          onTap: () => _openMap(location),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
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
                        Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                admin.username ?? 'No username',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                admin.email ?? 'No email',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (admin.lastLoginLocation != null)
                          _locationPreview(admin.lastLoginLocation!),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
