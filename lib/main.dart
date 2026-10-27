import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:async';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusFindApp());
}

/// ============================================================================
/// 1. APPLICATION & THEME SETUP
/// Navy Blue, White, and Teal color palette designed for a clean campus portal.
/// ============================================================================
class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom Brand Colors
    const primaryNavy = Color(0xFF0F2537); // Deep Navy Blue
    const secondaryTeal = Color(0xFF0D9488); // Fresh Teal Accent
    const scaffoldBg = Color(0xFFF8FAFC); // Crisp Light Slate

    return MaterialApp(
      title: 'CampusFind - Campus Lost & Found Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          primary: primaryNavy,
          secondary: secondaryTeal,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: secondaryTeal, width: 2),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Firebase login/signup gate. The existing CampusFind UI opens after login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Text('Authentication error: ${snapshot.error}'),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        return const MainScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final auth = FirebaseAuth.instance;
      if (_signup) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text,
        );
        final user = credential.user!;
        await user.updateDisplayName(_name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name.text.trim(), 'email': _email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          switch (e.code) {
            'email-already-in-use' => 'Ee email tho account already undhi.',
            'invalid-email' => 'Correct email enter cheyyi.',
            'weak-password' => 'Password at least 6 characters undali.',
            'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Email/password correct kaadhu.',
            'network-request-failed' => 'Internet connection check cheyyi.',
            _ => e.message ?? 'Authentication failed. Malli try cheyyi.',
          },
        )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2537);
    const teal = Color(0xFF0D9488);
       return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 54,
                        color: teal,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CampusFind',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _signup
                            ? 'Create your student account'
                            : 'Sign in to your campus portal',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 24),
                      if (_signup) ...[
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Name enter cheyyi'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            v == null || !v.trim().contains('@')
                                ? 'Valid email enter cheyyi'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _hidePassword = !_hidePassword,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6
                                ? 'Password at least 6 characters undali'
                                : null,
                      ),
                      if (_signup) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirm,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_reset),
                          ),
                          validator: (v) =>
                              v != _password.text
                                  ? 'Passwords match avvatledhu'
                                  : null,
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: navy,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _signup ? 'Create Account' : 'Login',
                              ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _signup = !_signup),
                        child: Text(
                          _signup
                              ? 'Already have an account? Login'
                              : 'New student? Create account',
                          style: const TextStyle(color: teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 2. DATA MODEL & SAMPLE DATA
/// Represents any item reported on campus (either Lost or Found).
/// ============================================================================
enum ItemType { lost, found }

class CampusItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final ItemType type;
  final String location;
  final String date;
  final String contactPerson;
  final String contactInfo;
  bool isResolved;
  final bool isMyReport;
  final String ownerId;

  CampusItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.location,
    required this.date,
    required this.contactPerson,
    required this.contactInfo,
    this.isResolved = false,
    this.isMyReport = false,
    this.ownerId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type.name,
      'location': location,
      'date': date,
      'contactPerson': contactPerson,
      'contactInfo': contactInfo,
      'isResolved': isResolved,
      'isMyReport': isMyReport,
      'ownerId': ownerId,
    };
  }

  factory CampusItem.fromJson(Map<String, dynamic> json) {
    return CampusItem(
      id: json['id'] as String? ?? 'item-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      type: (json['type'] as String?) == 'found' ? ItemType.found : ItemType.lost,
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      contactInfo: json['contactInfo'] as String? ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      isMyReport: json['isMyReport'] as bool? ?? false,
      ownerId: json['ownerId'] as String? ?? '',
    );
  }
}

// Initial realistic campus sample items
List<CampusItem> getInitialSampleItems() {
  return [
    CampusItem(
      id: 'item-1',
      title: 'College Student ID Card',
      description: 'Lost my student ID card with green lanyard. Name: Tejaswini N, Dept: CSE.',
      category: 'ID Cards',
      type: ItemType.lost,
      location: 'Near Central Library / Canteen Lawn',
      date: 'Today, 10:15 AM',
      contactPerson: 'Tejaswini N',
      contactInfo: 'tejaswini@campus.edu | Ph: +91 98765 43210',
      isResolved: false,
      isMyReport: true,
    ),
    CampusItem(
      id: 'item-2',
      title: 'Casio fx-991CW Scientific Calculator',
      description: 'Black modern Casio scientific calculator with white slider cover.',
      category: 'Electronics',
      type: ItemType.found,
      location: 'Science Block - Room 304 (Desk 12)',
      date: 'Today, 09:00 AM',
      contactPerson: 'Campus Security Desk',
      contactInfo: 'security@campus.edu | Room 102',
      isResolved: false,
      isMyReport: false,
    ),
    CampusItem(
      id: 'item-3',
      title: 'Milton Thermosteel Water Bottle (Blue)',
      description: '750ml blue metallic water bottle with a small NASA sticker on side.',
      category: 'Bottles & Tiffin',
      type: ItemType.found,
      location: 'Badminton Court Bleachers',
      date: 'Yesterday, 5:30 PM',
      contactPerson: 'Sports Dept Office',
      contactInfo: 'sports@campus.edu | Gym Block',
      isResolved: false,
      isMyReport: false,
    ),
    CampusItem(
      id: 'item-4',
      title: 'Brown Wildhorn Leather Wallet',
      description: 'Contains metro card, college bus pass, and emergency cash. Very urgent!',
      category: 'Wallets & Bags',
      type: ItemType.lost,
      location: 'Mechanical Block Seminar Hall',
      date: 'Yesterday, 2:15 PM',
      contactPerson: 'Rahul Verma',
      contactInfo: 'rahul.v@campus.edu | Ph: +91 98111 22334',
      isResolved: false,
      isMyReport: false,
    ),
    CampusItem(
      id: 'item-5',
      title: 'Dell 65W USB-C Laptop Charger',
      description: 'Original black Dell power adapter left plugged in on the second row.',
      category: 'Electronics',
      type: ItemType.found,
      location: 'Computer Lab 3 (Systems Block)',
      date: 'Oct 17, 2026',
      contactPerson: 'Lab Assistant (Mr. Ramesh)',
      contactInfo: 'lab3@campus.edu | Extension: 204',
      isResolved: false,
      isMyReport: false,
    ),
    CampusItem(
      id: 'item-6',
      title: 'Bike Keys with Marvel Keychain',
      description: 'Pair of Honda motorcycle keys attached to a red Spider-Man rubber keychain.',
      category: 'Keys',
      type: ItemType.found,
      location: 'Student Two-Wheeler Parking Gate 2',
      date: 'Oct 16, 2026',
      contactPerson: 'Parking Attendant Desk',
      contactInfo: 'security.gate2@campus.edu',
      isResolved: true,
      isMyReport: false,
    ),
    CampusItem(
      id: 'item-7',
      title: 'Algorithms Textbook (CLRS 3rd Edition)',
      description: 'Thick book with highlighted chapter 4 and sticky notes on graph algorithms.',
      category: 'Books & Notes',
      type: ItemType.lost,
      location: 'Reading Room 2, Ground Floor',
      date: 'Oct 15, 2026',
      contactPerson: 'Tejaswini N',
      contactInfo: 'tejaswini@campus.edu',
      isResolved: false,
      isMyReport: true,
    ),
  ];
}

/// ============================================================================
/// 3. MAIN SHELL SCREEN (Responsive Layout with Side/Bottom Navigation)
/// ============================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reportsSubscription;

  int _currentNavIndex = 0;
  List<CampusItem> _items = [];
  bool _isLoading = true;

  // Search and filter state for Home tab
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedTypeFilter = 'All'; // 'All', 'Lost', 'Found'

  final List<String> _categories = [
    'All',
    'Electronics',
    'ID Cards',
    'Wallets & Bags',
    'Books & Notes',
    'Bottles & Tiffin',
    'Keys',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _listenToReports();
  }

  // Listen to shared reports in Firestore. Reports are visible to signed-in students.
  void _listenToReports() {
    _reportsSubscription = FirebaseFirestore.instance.collection('reports')
      .orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final loaded = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final item = CampusItem.fromJson(data);
          return CampusItem(id: item.id, title: item.title, description: item.description,
            category: item.category, type: item.type, location: item.location, date: item.date,
            contactPerson: item.contactPerson, contactInfo: item.contactInfo,
            isResolved: item.isResolved, ownerId: item.ownerId,
            isMyReport: item.ownerId == uid);
        }).toList();
        if (mounted) setState(() { _items = loaded; _isLoading = false; });
      }, onError: (Object error) {
        debugPrint('Firestore reports stream error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reports load avvaledhu. Firestore Rules check cheyyi.')));
        }
      });
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _addNewItem(CampusItem newItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = FirebaseFirestore.instance.collection('reports').doc();
      await doc.set({
        ...newItem.toJson(), 'id': doc.id, 'ownerId': user.uid,
        'isMyReport': false, 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${newItem.type == ItemType.lost ? "Lost" : "Found"} report posted successfully!'),
          backgroundColor: const Color(0xFF0D9488), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report save avvaledhu: $e')));
    }
  }

  Future<void> _toggleResolveItem(CampusItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || item.ownerId != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mee own report matrame update cheyyagalru.')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('reports').doc(item.id)
        .update({'isResolved': !item.isResolved});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(item.isResolved ? 'Marked as Active again.' : 'Marked as Resolved! Great news.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _deleteItem(CampusItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || item.ownerId != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mee own report matrame delete cheyyagalru.')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('reports').doc(item.id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // Open the "Report Item" dialog
  void _showReportDialog({ItemType defaultType = ItemType.lost}) {
    showDialog(
      context: context,
      builder: (ctx) => ReportItemDialog(
        initialType: defaultType,
        categories: _categories.where((c) => c != 'All').toList(),
        onSubmit: _addNewItem,
      ),
    );
  }

  // Open full details of an item
  void _showItemDetails(CampusItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ItemDetailsDialog(
        item: item,
        onToggleResolve: () => _toggleResolveItem(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
        ),
      );
    }

    // Determine screen width for responsive desktop vs mobile layout
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 800;

    // Build the active view based on navigation selection
    Widget activeBody;
    switch (_currentNavIndex) {
      case 1:
        activeBody = MyReportsView(
          items: _items.where((i) => i.isMyReport).toList(),
          onTapItem: _showItemDetails,
          onToggleResolve: _toggleResolveItem,
          onDeleteItem: _deleteItem,
          onReportPressed: () => _showReportDialog(),
        );
        break;
      case 2:
        activeBody = ProfileView(
          itemsReportedCount: _items.where((i) => i.isMyReport).length,
          itemsResolvedCount: _items.where((i) => i.isMyReport && i.isResolved).length,
          onReportLost: () => _showReportDialog(defaultType: ItemType.lost),
          onReportFound: () => _showReportDialog(defaultType: ItemType.found),
        );
        break;
      case 0:
      default:
        activeBody = HomeDashboardView(
          items: _items,
          searchQuery: _searchQuery,
          selectedCategory: _selectedCategory,
          selectedTypeFilter: _selectedTypeFilter,
          categories: _categories,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
          onTypeFilterSelected: (type) => setState(() => _selectedTypeFilter = type),
          onTapItem: _showItemDetails,
          onReportLost: () => _showReportDialog(defaultType: ItemType.lost),
          onReportFound: () => _showReportDialog(defaultType: ItemType.found),
        );
        break;
    }

    // DESKTOP LAYOUT (Sidebar Navigation Rail)
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(),
            Expanded(
              child: Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: activeBody,
              ),
            ),
          ],
        ),
      );
    }

    // MOBILE / TABLET LAYOUT (AppBar + Bottom Navigation Bar)
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_searching_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'CampusFind',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Report Item',
            onPressed: () => _showReportDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: activeBody,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) => setState(() => _currentNavIndex = index),
        indicatorColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF0F2537)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF0F2537)),
            label: 'My Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF0F2537)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Modern Navy Sidebar for Desktop/Laptop screens
  Widget _buildDesktopSidebar() {
    const navyDark = Color(0xFF0F2537);
    const teal = Color(0xFF0D9488);

    return Container(
      width: 260,
      color: navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_searching_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CampusFind',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Lost & Found Portal',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Navigation Links
          _buildSidebarNavItem(
            icon: Icons.explore_rounded,
            label: 'Home & Explore',
            index: 0,
          ),
          _buildSidebarNavItem(
            icon: Icons.inventory_2_rounded,
            label: 'My Reports',
            index: 1,
            badgeCount: _items.where((i) => i.isMyReport && !i.isResolved).length,
          ),
          _buildSidebarNavItem(
            icon: Icons.person_rounded,
            label: 'My Campus Profile',
            index: 2,
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white12, height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 6),
          _buildSidebarLogoutItem(),
          const Spacer(),

          // Quick Action Box in Desktop Sidebar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: teal, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Campus Security',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Found valuables can also be deposited at Main Security Cabin, Room 102.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showReportDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Report an Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required int index,
    int? badgeCount,
  }) {
    final isSelected = _currentNavIndex == index;
    const teal = Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _currentNavIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? teal.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: teal.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? teal : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarLogoutItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Tooltip(
        message: 'Sign out of CampusFind',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF87171),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 4. VIEW 1: HOME DASHBOARD & EXPLORE
/// Contains welcome header, dashboard stats, report buttons, filters, and cards.
/// ============================================================================
class HomeDashboardView extends StatelessWidget {
  final List<CampusItem> items;
  final String searchQuery;
  final String selectedCategory;
  final String selectedTypeFilter;
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onTypeFilterSelected;
  final ValueChanged<CampusItem> onTapItem;
  final VoidCallback onReportLost;
  final VoidCallback onReportFound;

  const HomeDashboardView({
    super.key,
    required this.items,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedTypeFilter,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onTypeFilterSelected,
    required this.onTapItem,
    required this.onReportLost,
    required this.onReportFound,
  });

  @override
  Widget build(BuildContext context) {
    // Filter the items according to search, category, and type
    final filteredItems = items.where((item) {
      // Search match
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      // Category match
      final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;

      // Type match (Lost / Found)
      final matchesType = selectedTypeFilter == 'All' ||
          (selectedTypeFilter == 'Lost' && item.type == ItemType.lost) ||
          (selectedTypeFilter == 'Found' && item.type == ItemType.found);

      return matchesSearch && matchesCategory && matchesType;
    }).toList();

    // Stats calculations
    final totalReports = items.length;
    final lostCount = items.where((i) => i.type == ItemType.lost && !i.isResolved).length;
    final foundCount = items.where((i) => i.type == ItemType.found && !i.isResolved).length;
    final resolvedCount = items.where((i) => i.isResolved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome & Dashboard Hero Section
              _buildWelcomeHero(context),
              const SizedBox(height: 20),

              // 2. Stats Summary Row
              _buildStatsRow(
                total: totalReports,
                lost: lostCount,
                found: foundCount,
                resolved: resolvedCount,
              ),
              const SizedBox(height: 24),

              // 3. Search Bar & Type Segment
              _buildSearchAndTypeBar(context),
              const SizedBox(height: 16),

              // 4. Category Filter Chips
              _buildCategoryChips(),
              const SizedBox(height: 24),

              // 5. Section Title & Results Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTypeFilter == 'All'
                        ? 'All Active Listings'
                        : selectedTypeFilter == 'Lost'
                            ? 'Lost Items Listings'
                            : 'Found Items Listings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2537),
                    ),
                  ),
                  Text(
                    '${filteredItems.length} item${filteredItems.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Responsive Cards Grid / Empty State
              if (filteredItems.isEmpty)
                _buildEmptyState(context)
              else
                _buildResponsiveGrid(context, filteredItems),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Welcome banner with dual Report buttons
  Widget _buildWelcomeHero(BuildContext context) {
    const navy = Color(0xFF0F2537);
    const teal = Color(0xFF0D9488);
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: teal),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Official Campus Portal',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome to CampusFind 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Misplaced your keys, ID card, or calculator? Or found an item someone left behind? Help our campus community reconnect with their belongings.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Report Lost & Report Found
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C), // Orange/Coral for Lost
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onReportLost,
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text(
                  'Report Lost Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal, // Teal for Found
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onReportFound,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Report Found Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dashboard Summary Counters
  Widget _buildStatsRow({
    required int total,
    required int lost,
    required int found,
    required int resolved,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final count = isSmall ? 2 : 4;
        final cardWidth = (constraints.maxWidth - (count - 1) * 12) / count;

        final statCards = [
          _buildStatCard(
            title: 'Total Active',
            count: total.toString(),
            icon: Icons.dashboard_outlined,
            color: const Color(0xFF0F2537),
            width: cardWidth,
          ),
          _buildStatCard(
            title: 'Lost Items',
            count: lost.toString(),
            icon: Icons.search_off_rounded,
            color: const Color(0xFFEA580C),
            width: cardWidth,
          ),
          _buildStatCard(
            title: 'Found Items',
            count: found.toString(),
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF0D9488),
            width: cardWidth,
          ),
          _buildStatCard(
            title: 'Recovered',
            count: resolved.toString(),
            icon: Icons.celebration_outlined,
            color: const Color(0xFF2563EB),
            width: cardWidth,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar with Type Filter (All / Lost / Found)
  Widget _buildSearchAndTypeBar(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final searchField = TextField(
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by keyword, item name, or campus location...',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onSearchChanged(''),
              )
            : null,
      ),
    );

    final typeSelector = SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'All', label: Text('All')),
        ButtonSegment(value: 'Lost', label: Text('Lost')),
        ButtonSegment(value: 'Found', label: Text('Found')),
      ],
      selected: {selectedTypeFilter},
      onSelectionChanged: (newSelection) {
        onTypeFilterSelected(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0D9488);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF0F2537);
        }),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: typeSelector),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        typeSelector,
      ],
    );
  }

  /// Horizontal Category Chips
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onCategorySelected(cat);
              },
              selectedColor: const Color(0xFF0F2537),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF0F2537) : const Color(0xFFCBD5E1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Responsive Grid of Campus Items
  Widget _buildResponsiveGrid(BuildContext context, List<CampusItem> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate columns based on available width:
        // >= 950 -> 3 columns
        // 600 - 949 -> 2 columns
        // < 600 -> 1 column
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 580) {
          crossAxisCount = 2;
        }

        final double spacing = 16;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: list.map((item) {
            return SizedBox(
              width: itemWidth,
              child: CampusItemCard(
                item: item,
                onTap: () => onTapItem(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching items found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search keywords, clearing filters, or report the item if it\'s missing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              onSearchChanged('');
              onCategorySelected('All');
              onTypeFilterSelected('All');
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 5. ITEM CARD COMPONENT
/// Clean card with badge, category icon, date, location, and interactive tap.
/// ============================================================================
class CampusItemCard extends StatelessWidget {
  final CampusItem item;
  final VoidCallback onTap;

  const CampusItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_rounded;
      case 'ID Cards':
        return Icons.badge_rounded;
      case 'Wallets & Bags':
        return Icons.wallet_rounded;
      case 'Books & Notes':
        return Icons.menu_book_rounded;
      case 'Bottles & Tiffin':
        return Icons.coffee_rounded;
      case 'Keys':
        return Icons.vpn_key_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == ItemType.lost;
    final badgeColor = isLost ? const Color(0xFFEA580C) : const Color(0xFF0D9488);
    final badgeBg = isLost ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDFA);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Type Badge + Category Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLost ? Icons.search_rounded : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLost ? 'LOST' : 'FOUND',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'RESOLVED',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(item.category),
                          size: 14,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2537),
                ),
              ),
              const SizedBox(height: 6),

              // Description snippet
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),

              // Location info
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: Color(0xFF0D9488)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date info
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    item.date,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  const Text(
                    'Details →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 6. VIEW 2: MY REPORTS
/// Manage the student's personal reported items (Mark as resolved or delete).
/// ============================================================================
class MyReportsView extends StatelessWidget {
  final List<CampusItem> items;
  final ValueChanged<CampusItem> onTapItem;
  final ValueChanged<CampusItem> onToggleResolve;
  final ValueChanged<CampusItem> onDeleteItem;
  final VoidCallback onReportPressed;

  const MyReportsView({
    super.key,
    required this.items,
    required this.onTapItem,
    required this.onToggleResolve,
    required this.onDeleteItem,
    required this.onReportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2537),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keep track of lost or found items you have reported.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onReportPressed,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Report'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 16),
                      const Text(
                        'No items reported yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'When you report a lost or found item, it will show up here so you can track or mark it as returned.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2537),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onReportPressed,
                        child: const Text('Create your first report'),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLost = item.type == ItemType.lost;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isLost
                                        ? const Color(0xFFFFF7ED)
                                        : const Color(0xFFF0FDFA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLost ? 'LOST ITEM' : 'FOUND ITEM',
                                    style: TextStyle(
                                      color: isLost ? const Color(0xFFEA580C) : const Color(0xFF0D9488),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (item.isResolved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'RESOLVED',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  item.date,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2537),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 14, color: Color(0xFF0D9488)),
                                const SizedBox(width: 4),
                                Text(
                                  item.location,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 8),

                            // Action buttons: Details, Mark as Resolved, Delete
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => onTapItem(item),
                                  icon: const Icon(Icons.visibility_outlined, size: 16),
                                  label: const Text('View Details'),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: item.isResolved
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF0D9488),
                                    side: BorderSide(
                                      color: item.isResolved
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF0D9488),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => onToggleResolve(item),
                                  icon: Icon(
                                    item.isResolved
                                        ? Icons.undo_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    item.isResolved ? 'Reopen' : 'Mark as Resolved',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  tooltip: 'Delete Report',
                                  onPressed: () => onDeleteItem(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 7. VIEW 3: PROFILE & CAMPUS HELPDESK GUIDELINES
/// Clean student profile with safe exchange tips and security contacts.
/// ============================================================================
class ProfileView extends StatelessWidget {
  final int itemsReportedCount;
  final int itemsResolvedCount;
  final VoidCallback onReportLost;
  final VoidCallback onReportFound;

  const ProfileView({
    super.key,
    required this.itemsReportedCount,
    required this.itemsResolvedCount,
    required this.onReportLost,
    required this.onReportFound,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Identity Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF0F2537),
                          child: const Text(
                            'TN',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tejaswini N',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2537),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Student • B.Tech Computer Science & Eng.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0D9488)),
                                  SizedBox(width: 4),
                                  Text(
                                    'ID: CAMPUS-2026-8841',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),

                    // Quick User Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStat('Reports Posted', '$itemsReportedCount'),
                        _buildProfileStat('Items Recovered', '$itemsResolvedCount'),
                        _buildProfileStat('Community Karma', '★ 150 pts'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Safe Campus Guidelines Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF0D9488)),
                        SizedBox(width: 8),
                        Text(
                          'Campus Lost & Found Guidelines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF134E4A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuidelineItem(
                      icon: Icons.meeting_room_outlined,
                      title: 'Official Collection Center',
                      desc: 'Valuable items like laptops, wallets, and phones can be deposited directly at Main Security Office (Room 102, Admin Block).',
                    ),
                    const SizedBox(height: 8),
                    _buildGuidelineItem(
                      icon: Icons.fingerprint_rounded,
                      title: 'Verify Ownership',
                      desc: 'Before handing an item to a claimant, verify their student ID card or ask for proof of ownership (like unlocking a phone screen).',
                    ),
                    const SizedBox(height: 8),
                    _buildGuidelineItem(
                      icon: Icons.schedule_rounded,
                      title: '30-Day Retention Policy',
                      desc: 'Unclaimed items are retained at student welfare affairs for 30 calendar days before public campus auction.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campus Emergency & Help Contacts
              const Text(
                'Campus Help & Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2537),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2537).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF0F2537)),
                      ),
                      title: const Text('Campus Main Security Desk', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Admin Block Ground Floor • Ext: 101'),
                      trailing: const Text(
                        'Open 24x7',
                        style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_library_rounded, color: Color(0xFF0D9488)),
                      ),
                      title: const Text('Central Library Lost & Found', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Circulation Counter • Ext: 205'),
                      trailing: const Text(
                        '8 AM - 8 PM',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2537),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2537),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ============================================================================
/// 8. DIALOG: REPORT ITEM (Lost or Found)
/// Modal form enabling the user to report a new item locally.
/// ============================================================================
class ReportItemDialog extends StatefulWidget {
  final ItemType initialType;
  final List<String> categories;
  final ValueChanged<CampusItem> onSubmit;

  const ReportItemDialog({
    super.key,
    required this.initialType,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<ReportItemDialog> createState() => _ReportItemDialogState();
}

class _ReportItemDialogState extends State<ReportItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late ItemType _selectedType;
  late String _selectedCategory;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactNameController = TextEditingController(text: 'Tejaswini N');
  final _contactInfoController = TextEditingController(text: 'tejaswini@campus.edu');

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newItem = CampusItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        location: _locationController.text.trim(),
        date: 'Just now',
        contactPerson: _contactNameController.text.trim(),
        contactInfo: _contactInfoController.text.trim(),
        isResolved: false,
        isMyReport: true,
        ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      widget.onSubmit(newItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _selectedType == ItemType.lost;
    final primaryColor = isLost ? const Color(0xFFEA580C) : const Color(0xFF0D9488);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLost ? 'Report Lost Item' : 'Report Found Item',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2537),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Report Type Selector
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedType = ItemType.lost),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isLost ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Lost Item',
                            style: TextStyle(
                              color: isLost ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedType = ItemType.found),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isLost ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Found Item',
                            style: TextStyle(
                              color: !isLost ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item Title
                const Text('Item Name / Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: isLost ? 'e.g., Black Dell Laptop Charger' : 'e.g., Blue Water Flask',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter the item name' : null,
                ),
                const SizedBox(height: 14),

                // Category & Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(),
                            items: widget.categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Location Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLost ? 'Lost At Location *' : 'Found At Location *',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Library 2nd Floor',
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Location is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                const Text('Description & Specific Details *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isLost
                        ? 'Describe brand, color, unique marks, stickers, or case to help identify it.'
                        : 'Describe where it was found and current safe keeping place.',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please add a short description' : null,
                ),
                const SizedBox(height: 14),

                // Contact Details
                const Text('Contact Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contactInfoController,
                  decoration: const InputDecoration(
                    hintText: 'Email or Mobile number for student coordination',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Contact info is required' : null,
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submit,
                      child: const Text('Post Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 9. DIALOG: ITEM DETAILS MODAL
/// Shows complete information, safety reminder, and resolution action.
/// ============================================================================
class ItemDetailsDialog extends StatelessWidget {
  final CampusItem item;
  final VoidCallback onToggleResolve;

  const ItemDetailsDialog({
    super.key,
    required this.item,
    required this.onToggleResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == ItemType.lost;
    final badgeColor = isLost ? const Color(0xFFEA580C) : const Color(0xFF0D9488);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Status Badge and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      isLost ? 'LOST ITEM' : 'FOUND ITEM',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (item.isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'RESOLVED / RETURNED',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2537),
                ),
              ),
              const SizedBox(height: 8),

              // Category and Date chip row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reported: ${item.date}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, color: Color(0xFF0D9488), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Campus Location',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.location,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description & Notes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F2537)),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 16),

              // Contact & Claim Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.contact_mail_outlined, color: Color(0xFF0D9488), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isLost ? 'Contact Item Owner' : 'Finder Contact / Safe Location',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2537),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reported by: ${item.contactPerson}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contact: ${item.contactInfo}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.isMyReport)
                    TextButton.icon(
                      onPressed: () {
                        onToggleResolve();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        item.isResolved ? Icons.undo_rounded : Icons.check_circle_rounded,
                        color: const Color(0xFF0D9488),
                      ),
                      label: Text(
                        item.isResolved ? 'Mark as Active' : 'Mark as Resolved',
                        style: const TextStyle(color: Color(0xFF0D9488)),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2537),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
