import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/property_service.dart';
import '../../global/auth_data.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _leaseDurationController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();

  String _type = 'house';
  String _transactionType = 'rent';
  bool _isAvailable = true;
  DateTime? _availableFrom;
  List<XFile> _images = [];
  bool _isSubmitting = false;

  final List<String> _amenitiesOptions = [
    'water',
    'electricity',
    'security',
    'parking',
    'internet',
    'furnished',
    'air_conditioning',
  ];
  final Set<String> _selectedAmenities = {};

  final Map<String, String> typeOptions = {
    'house': 'House',
    'shop': 'Shop',
  };

  final Map<String, String> transactionTypeOptions = {
    'rent': 'Rent',
    'sale': 'Sale',
  };

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and add at least one image.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await PropertyService().createProperty(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text),
        propertyType: _type,
        transactionType: _transactionType,
        images: _images, // Pass XFile list directly
        landlordId: AuthData.landlordId!,
        locationDetails: {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
        },
        amenities: _selectedAmenities.toList(),
        availability: _transactionType == 'rent'
            ? {
                'isAvailable': _isAvailable,
                'availableFrom': _availableFrom?.toIso8601String(),
                'leaseDurationMonths': _leaseDurationController.text.isNotEmpty
                    ? int.tryParse(_leaseDurationController.text)
                    : null,
              }
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add property: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildImageWidget(XFile img) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: img.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              height: 80,
              width: 80,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else {
      return Image.file(
        File(img.path),
        height: 80,
        width: 80,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                items: transactionTypeOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _transactionType = value!),
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _transactionType == 'rent' ? 'Rent Price' : 'Sale Price',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Bedrooms'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: typeOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 10),
              const Text('Select Amenities'),
              Wrap(
                spacing: 8,
                children: _amenitiesOptions.map((amenity) {
                  return FilterChip(
                    label: Text(amenity),
                    selected: _selectedAmenities.contains(amenity),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              if (_transactionType == 'rent') ...[
                SwitchListTile(
                  title: const Text('Is Available'),
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
                if (_isAvailable) ...[
                  ListTile(
                    title: Text(
                      _availableFrom == null
                          ? 'Select Available From Date'
                          : 'Available From: ${DateFormat.yMMMd().format(_availableFrom!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _availableFrom = picked);
                      }
                    },
                  ),
                  TextFormField(
                    controller: _leaseDurationController,
                    decoration: const InputDecoration(labelText: 'Lease Duration (months)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Pick Images'),
                onPressed: _pickImages,
              ),
              if (_images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _images.map(_buildImageWidget).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}