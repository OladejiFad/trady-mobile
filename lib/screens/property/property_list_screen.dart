import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../global/auth_data.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/property/property_card.dart';
import '../property/edit_property_screen.dart';
import '../../widgets/buyer_info_form.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  late Future<List<Property>> _futureProperties;
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  String _searchQuery = '';
  String _selectedType = 'All';
  final _types = ['All', 'Rent', 'Sale'];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  void _fetchProperties() {
    final future = AuthData.role == 'landlord'
        ? PropertyService().fetchPropertiesByLandlord(AuthData.landlordId!)
        : PropertyService().fetchApprovedProperties();

    _futureProperties = future;
    _futureProperties.then((properties) {
      setState(() {
        _allProperties = properties;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _allProperties.where((p) {
        final address = p.location.address.toLowerCase();
        final matchSearch = address.contains(_searchQuery.toLowerCase());
        final type = p.type.toLowerCase();
        final matchType =
            _selectedType == 'All' || type == _selectedType.toLowerCase();
        return matchSearch && matchType;
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    _fetchProperties();
  }

  Future<void> _onMessageClicked(
      String landlordName, String landlordId, String propertyId) async {
    await showDialog(
      context: context,
      builder: (_) => BuyerInfoForm(
        landlordId: landlordId,
        landlordName: landlordName,
        propertyId: propertyId,
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Property Listings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _calculateCrossAxisCount(width);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Search by location',
                          labelStyle:
                              GoogleFonts.poppins(color: Colors.grey[600]),
                          prefixIcon:
                              const Icon(Icons.search, color: Color(0xFF3F51B5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        items: _types
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.poppins(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Type',
                          labelStyle:
                              GoogleFonts.poppins(color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF3F51B5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF3F51B5),
                child: FutureBuilder<List<Property>>(
                  future: _futureProperties,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _allProperties.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3F51B5)),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.redAccent),
                        ),
                      );
                    }
                    if (_filteredProperties.isEmpty) {
                      return Center(
                        child: Text(
                          'No properties found',
                          style: GoogleFonts.poppins(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _filteredProperties.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                       childAspectRatio: width < 600 ? 0.95 : width < 900 ? 1.1 : 1.3,

                      ),
                      itemBuilder: (context, index) {
                        final property = _filteredProperties[index];
                        return PropertyCard(
                          property: property,
                          onMessageLandlord: () {
                            _onMessageClicked(
                              property.landlordName ?? '',
                              property.landlordId,
                              property.id,
                            );
                          },
                          onEdit: AuthData.role == 'landlord'
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditPropertyScreen(property: property),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _fetchProperties();
                                    }
                                  });
                                }
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
