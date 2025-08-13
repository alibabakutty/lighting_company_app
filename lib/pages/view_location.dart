import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewLocation extends StatefulWidget {
  const ViewLocation({super.key});

  @override
  State<ViewLocation> createState() => _ViewLocationState();
}

class _ViewLocationState extends State<ViewLocation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Location')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/fetch_location_admin');
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Admins Location'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/fetch_location_executive');
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Executives Location'),
            ),
          ],
        ),
      ),
    );
  }
}
