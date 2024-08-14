import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../map_screen.dart';

class AddPurchasedCoffee extends StatefulWidget {
  const AddPurchasedCoffee({super.key});

  @override
  _AddPurchasedCoffeeState createState() => _AddPurchasedCoffeeState();
}

class _AddPurchasedCoffeeState extends State<AddPurchasedCoffee> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _coffeeShopController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(text: "0.00");
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _coffeeNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final picker = ImagePicker();

  // Coffee Type and Coffee Size
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _coffeeSizes = [];
  List<Map<String, dynamic>> _coffeeTypes = [];
  String? _selectedCoffeeSize;
  String? _selectedCoffeeType;

  @override
  void initState() {
    super.initState();
    _loadCoffeeData();
  }

  Future<void> _loadCoffeeData() async {
    final coffeeSizes = await _firestoreService.fetchCoffeeSizes();
    final coffeeTypes = await _firestoreService.fetchCoffeeTypes();
    setState(() {
      _coffeeTypes = coffeeTypes;
      _coffeeSizes = coffeeSizes;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = "${_selectedDate!.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        final localizations = MaterialLocalizations.of(context);
        final formattedTime = localizations.formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: true);
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    // Process the recognized text into lines
    String extractedText = _processRecognizedText(recognizedText);
    print('Extracted text: $extractedText');  // Debug print

    // Reset fields
    setState(() {
        _coffeeShopController.text = '';
        _selectedCoffeeType = null;
        _priceController.text = '';
        _dateController.text = '';
        _timeController.text = '';
        _coffeeNameController.text = '';
    });

    bool coffeeTypeFound = false;

    if (extractedText.isNotEmpty) {
      setState(() {
        _coffeeShopController.text = _extractShopName(extractedText);
        _selectedCoffeeType = _extractCoffeeType(extractedText);
        _priceController.text = _extractPrice(extractedText);
        _dateController.text = _extractDate(extractedText);
        _timeController.text = _extractTime(extractedText);
        _coffeeNameController.text = _extractCoffeeName(extractedText);
        coffeeTypeFound = _selectedCoffeeType != null; // Check if coffee type is found
      });

      String address = _extractAddress(extractedText);
      print('Address before searchAddress: $address'); // debug
      if (address.isNotEmpty) {
        await _searchAddress(address);
      } else {
        _pickAddressOnMap();
      }
    }

    textRecognizer.close();

    if (!coffeeTypeFound) {
      // Show notification if coffee type was not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No coffee type matched from the receipt. Please enter details manually.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _processRecognizedText(RecognizedText recognizedText) {
    // List to hold text blocks along with their bounding boxes
    List<Map<String, dynamic>> textBlocks = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        textBlocks.add({
          'text': line.text,
          'boundingBox': line.boundingBox,
        });
      }
    }

    // Sort text blocks by top-to-bottom, then left-to-right
    textBlocks.sort((a, b) {
      Rect aRect = a['boundingBox'];
      Rect bRect = b['boundingBox'];

      // First, sort by top position
      int topComparison = aRect.top.compareTo(bRect.top);
      if (topComparison != 0) return topComparison;

      // If top positions are equal, sort by left position
      return aRect.left.compareTo(bRect.left);
    });

    // Concatenate sorted text
    StringBuffer extractedText = StringBuffer();
    for (var block in textBlocks) {
      extractedText.writeln(block['text']);
    }

    return extractedText.toString().trim();
  }

  // Example extraction functions

  String _extractCoffeeName(String text) {
    return _extractCoffeeType(text) ?? '';
  }

  String _extractShopName(String text) {
    // list of coffee shops
    List<String> coffeeShops = [
      'Costa',
      'Starbucks',
      'Tim Hortons',
      'Dunkin',
      'McCafe',
      'Caffe Nero',
      'Pret A Manger',
      'Greggs',
      'Esquires Coffee',
      'Patisserie Valerie',
      'Cafe Ritazza',
      'Black Sheep',
      'Esquires'
    ];
    String pattern = coffeeShops.join('|');
    RegExp regex = RegExp('($pattern)', caseSensitive: false);
    Match? match = regex.firstMatch(text);

    if (match != null) {
      String matchedText = match.group(0)!;
      // Capitalize the first letter
      return matchedText[0].toUpperCase() + matchedText.substring(1).toLowerCase();
    } else {
      return '';
    }
  }

  String? _extractCoffeeType(String text) {
    for (var coffee in _coffeeTypes) {
      if (text.toLowerCase().contains(coffee['coffee_type_desc'].toLowerCase())) {
        return coffee['coffee_type_desc'];
      }
    }
    return null;
  }

  String _extractPrice(String text) {
    List<String> lines = text.split(r'\s+'); // splitting by whitespace (\s)
    Map<String, String> coffeePrices = {};

    // Regex to find the price on the same line as a coffee type
    RegExp priceRegex = RegExp(r'(\d+\.\d{2})');

    for (String line in lines) {
      for (var coffee in _coffeeTypes) {
        String coffeeType = coffee['coffee_type_desc'];
        if (line.toLowerCase().contains(coffeeType.toLowerCase())) {
          Match? priceMatch = priceRegex.firstMatch(line);
          if (priceMatch != null) {
            coffeePrices[coffeeType] = priceMatch.group(0)!;
          }
        }
      }
    }

    // Extract and return the price of the first matched coffee type
    if (coffeePrices.isNotEmpty) {
      return coffeePrices.values.toSet().join(', ');
    } else {
      return '';
    }
  }

  String _extractDate(String text) {
    List<String> dateFormats = [
      r'\b(\d{2}/\d{2}/\d{4})\b',  // DD/MM/YYYY
      r'\b(\d{1}/\d{2}/\d{4})\b',  // D/MM/YYYY
      r'\b(\d{2}-\d{2}-\d{4})\b',  // DD-MM-YYYY
      r'\b(\d{1}-\d{2}-\d{4})\b',  // D-MM-YYYY
      r'\b(\d{2}[A-Za-z]{3}\d{2})\b',  // DDMMMYY
      r'\b(\d{2} [A-Za-z]{3} \d{2})\b',  // DD MMM YY
      r'\b(\d{2}[A-Za-z]{3}\d{4})\b',  // DDMMMYYYY
      r'\b(\d{2} [A-Za-z]{3} \d{4})\b',  // DD MMM YYYY
      r"\b(\d{2}[A-Za-z]{3}'\d{2})\b",  // DDMMM'YY
      r"\b(\d{2} [A-Za-z]{3}' \d{2})\b",  // DD MMM' YY
      r"\b(\d{2} [A-Za-z]{3}'\d{2})\b",  // DD MMM'YY
      r"\b(\d{2}[A-Za-z]{3}' \d{2})\b",  // DDMMM' YY
    ];

    List<String> datePatterns = [
      'dd/MM/yyyy',
      'd/MM/yyyy',
      'dd-MM-yyyy',
      'd-MM-yyyy',
      'ddMMMyy',
      'dd MMM yy',
      'ddMMMyyyy',
      'dd MMM yyyy',
      "ddMMM'yy",
      "dd MMM' yy",
      "dd MMM'yy",
      "ddMMM' yy",
    ];

    for (int i = 0; i < dateFormats.length; i++) {
      RegExp regex = RegExp(dateFormats[i]);
      Match? match = regex.firstMatch(text);
      if (match != null) {
        String dateString = match.group(0)!;
        try {
          return _parseDate(dateString, datePatterns[i]);
        } catch (e) {
          // Continue to the next pattern
        }
      }
    }
    return '';
  }

  String _capitalizeMonth(String dateString) {
    RegExp monthRegex = RegExp(r"[A-Za-z]{3}");
    return dateString.replaceAllMapped(monthRegex, (match) {
      String month = match.group(0)!;
      return month[0].toUpperCase() + month.substring(1).toLowerCase();
    });
  }

  String _parseDate(String dateString, String pattern) {
    try {
      // Adjust the year for 'yy format before parsing
      if (pattern.contains("yy") && !pattern.contains("yyyy")) {
        dateString = dateString.replaceFirstMapped(RegExp(r"(\d{2})$"), (match) {
          int year = int.parse(match.group(1)!);
          String newYear = (year + 2000).toString();
          return newYear; // Always add 2000 to the year
        });
        pattern = pattern.replaceFirst("yy", "yyyy");
      }

      // Capitalize month name in dateString
      dateString = _capitalizeMonth(dateString);

      // Handle single quote in pattern correctly
      pattern = pattern.replaceAll("'", "''");

      DateTime date = DateFormat(pattern).parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return '';
    }
  }

// --------------------------------------------------------------------------------------- // 

// ExtractTime

  String _cleanTimeString(String timeString) {
    // Remove PM/AM if it's 24-hour format time
    RegExp regex = RegExp(r'\b(\d{1,2}):(\d{2})\s?(AM|PM)\b', caseSensitive: false);
    if (regex.hasMatch(timeString)) {
      Match? match = regex.firstMatch(timeString);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        if (hour >= 13) {
          return "${match.group(1)}:${match.group(2)}"; // Remove AM/PM for 24-hour format
        }
      }
    }
    return timeString;
  }

  String _extractTime(String text) {
    List<String> timeFormats = [
      r'\b(\d{1,2}:\d{2}\s?(AM|PM)?)\b',  // 12-hour format with optional AM/PM
      r'\b(\d{1,2}:\d{2})\b',  // 24-hour format
    ];

    List<String> timePatterns = [
      'h:mm a',  // 12-hour format with AM/PM
      'H:mm',  // 24-hour format
    ];

    for (int i = 0; i < timeFormats.length; i++) {
      RegExp regex = RegExp(timeFormats[i]);
      Match? match = regex.firstMatch(text);
      if (match != null) {
        String timeString = match.group(0)!;
        timeString = _cleanTimeString(timeString);  // Clean the time string
        try {
          DateFormat inputFormat = DateFormat(timePatterns[i]);
          DateTime dateTime = inputFormat.parse(timeString);
          DateFormat outputFormat = DateFormat('HH:mm');
          return outputFormat.format(dateTime);
        } catch (e) {
          // Continue to the next pattern
        }
      }
    }
    return '';
  }

// --------------------------------------------------------------------------------------- // 

// ExtractAddress

  String _extractAddress(String text) {
    RegExp postcodeRegex = RegExp(r'\b([A-Z]{1,2}[0-9R][0-9A-Z]? ?[0-9][ABD-HJLNP-UW-Z]{2})\b', caseSensitive: false);
    List<String> lines = text.split('\n');
    String address = '';

    for (int i = 0; i < lines.length; i++) {
      if (postcodeRegex.hasMatch(lines[i])) {
        int startIndex = (i - 3) >= 0 ? (i - 3) : 0;
        int endIndex = i + 1;
        address = lines.sublist(startIndex, endIndex).join(', ');
        print('Addres: $address'); // debug
        break;
      }
    }
    return address;
  }

  Future<void> _searchAddress(String address) async {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      Location location = locations.first;
      String addressLatLng = "${location.latitude}, ${location.longitude}";
      print(addressLatLng); // debug
      
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          String foundAddress = "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
          setState(() {
            _addressController.text = foundAddress;
          });
          print(foundAddress); // debug
        }
        else {
          _pickAddressOnMap();
        }
      }
      else {
        _pickAddressOnMap();
      }
  }

  void _pickAddressOnMap() async {
    LatLng? addressLatLng;

    if (_addressController.text.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(_addressController.text);
        if (locations.isNotEmpty) {
          addressLatLng = LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        print('Error: $e');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          onLocationPicked: (address) {
            setState(() {
              _addressController.text = address;
            }); 
          },
          initialPosition: addressLatLng,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      await _processImage(inputImage);
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text('Import from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _saveData() async {

    setState(() {
      if (_priceController.text.isEmpty) {
      _priceController.text = "0.00";
      } else {
        double price = double.parse(_priceController.text);
        _priceController.text = price.toStringAsFixed(2);
      }

      _coffeeShopController.text = _coffeeShopController.text.toUpperCase();

    });
    
    if (_selectedCoffeeType == null ||
        _selectedCoffeeSize == null ||
        _coffeeShopController.text.isEmpty ||
        _volumeController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _addressController.text.isEmpty) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields (*)',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare data to save
    String deviceUUID = await _firestoreService.getDeviceUUID();
    Map<String, dynamic> newRecord = {
      'purchase_id': DateTime.now().millisecondsSinceEpoch, // Unique ID
      'device_uuid': deviceUUID,  
      'coffee_name': _coffeeNameController.text,
      'coffee_type_desc': _selectedCoffeeType,
      'coffee_size_desc': _selectedCoffeeSize,
      'volume': int.parse(_volumeController.text.isEmpty ? '0' : _volumeController.text),
      'price': double.parse(_priceController.text.isEmpty ? '0.00' : _priceController.text),
      'coffee_shop': _coffeeShopController.text,
      'brand': '',
      'notes': _notesController.text,
      'shop_address': _addressController.text,
      'date': _dateController.text,
      'time': _timeController.text,
      'is_purchased': true,
      'is_homemade': false,
      'is_vendingmachine': false,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Save data to Firestore
    await _firestoreService.addCoffeeRecord(newRecord);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Record saved successfully!',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 230,
          left: 15,
          right: 15,
        ),
        
      ),
    );

    // back to two previous page
    Navigator.of(context)..pop()..pop();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          centerTitle: true,
          title: Text(
            'Purchased Coffee',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        const Icon(Icons.camera_alt, size: 30),
                        const SizedBox(width: 10),
                        Text('Receipt Photo',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a photo or import of your receipt for automatic data extraction. Verify that the extracted data is accurate. You can edit the data if needed.', //\nIt can make mistakes. Check and edit your info.
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _showImageSourceActionSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          'Take Photo',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        const Icon(Icons.local_cafe, size: 30),
                        const SizedBox(width: 10),
                        Text('Coffee Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('\t\t * Field is required',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.red
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _coffeeNameController,
                      decoration: InputDecoration(
                        labelText: 'Coffee Name (Optional)',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCoffeeType,
                      decoration: InputDecoration(
                        labelText: 'Coffee Type*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: _coffeeTypes.map<DropdownMenuItem<String>>((type) {
                        return DropdownMenuItem<String>(
                          value: type['coffee_type_desc'],
                          child: Text(type['coffee_type_desc']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoffeeType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCoffeeSize,
                      decoration: InputDecoration(
                        labelText: 'Coffee Size*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: _coffeeSizes.map((size) {
                        return DropdownMenuItem<String>(
                          value: size['coffee_size_desc'],
                          child: Text(size['coffee_size_desc']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoffeeSize = newValue;
                          // Automatically fill volume based on selected coffee size
                          if (newValue == 'Small') {
                            _volumeController.text = '227';
                          } else if (newValue == 'Medium') {
                            _volumeController.text = '341';
                          } else if (newValue == 'Large') {
                            _volumeController.text = '455';
                          } else if (newValue == 'Extra Large') {
                            _volumeController.text = '568';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _volumeController,
                            decoration: InputDecoration(
                              labelText: 'Estimated Volume (mL)*',
                              labelStyle: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.grey[600]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Volume Information', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                                  content: SingleChildScrollView(
                                    child: Table(
                                      border: TableBorder.all(color: Colors.grey),
                                      columnWidths: const <int, TableColumnWidth>{
                                        0: FlexColumnWidth(),
                                        1: FixedColumnWidth(50),
                                        2: FixedColumnWidth(50),
                                      },
                                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                      children: <TableRow>[
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Size', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Oz.', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('mL.', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Small', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('8', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('227', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Medium', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('12', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('341', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Large', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('16', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('455', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Extra-large', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('20', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('568', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Close', style: GoogleFonts.montserrat(fontSize: 14)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _coffeeShopController,
                      decoration: InputDecoration(
                        labelText: 'Coffee Shop*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Date*',
                            labelStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _timeController,
                          decoration: InputDecoration(
                            labelText: 'Time*',
                            labelStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: "Shop's Address*",
                              labelStyle: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            readOnly: true,  // Make the address field read-only
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: _pickAddressOnMap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                          padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 45),
          ],
        ),
      ),
    );
  }
}
