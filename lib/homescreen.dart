import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> journalEntries = [];
  int _selectedIndex = 0;
  DateTime _selectedDay = DateTime.now();
  String currentUsername = '';
  bool _isLoading = true;
  int daysJournaled = 0;
  int totalWordCount = 0;

  final List<String> _quotes = [
    "Believe in yourself!",
    "Stay positive and happy.",
    "Every day is a fresh start.",
    "You are stronger than you think."
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // Get the current logged-in user
  Future<void> _getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('currentUser');

      if (username != null) {
        setState(() {
          currentUsername = username;
        });
        _loadJournalStats();
      } else {
        // No user logged in, redirect to login
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  // Load journal statistics from Firestore
  Future<void> _loadJournalStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('journal_entries')
          .where('user', isEqualTo: currentUsername)
          .get();

      List<Map<String, dynamic>> entries = [];
      int wordCount = 0;

      // Process each journal entry
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Add to entries list
        entries.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'entry': data['entry'] ?? '',
          'date': data['date'],
          'mood': data['mood'] ?? 'Happy',
        });

        // Count words in this entry
        String entryText = data['entry'] ?? '';
        wordCount +=
            entryText.split(' ').where((word) => word.trim().isNotEmpty).length;
      }

      // Get unique days
      Set<String> uniqueDays = {};
      for (var entry in entries) {
        if (entry['date'] is Timestamp) {
          DateTime entryDate = (entry['date'] as Timestamp).toDate();
          uniqueDays
              .add('${entryDate.year}-${entryDate.month}-${entryDate.day}');
        }
      }

      setState(() {
        journalEntries = entries;
        daysJournaled = uniqueDays.length;
        totalWordCount = wordCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading journal statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getDailyQuote() {
    return _quotes[Random().nextInt(_quotes.length)];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushNamed(context, '/journal');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  bool isTodayJournaled() {
    DateTime today = DateTime.now();
    String todayDate = "${today.year}-${today.month}-${today.day}";

    for (var entry in journalEntries) {
      if (entry['date'] is Timestamp) {
        DateTime entryDate = (entry['date'] as Timestamp).toDate();
        String formatted =
            "${entryDate.year}-${entryDate.month}-${entryDate.day}";
        if (formatted == todayDate) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text("Home", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJournalStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: _selectedDay,
                  calendarFormat: CalendarFormat.week,
                  headerStyle: const HeaderStyle(formatButtonVisible: false),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Days Journaled",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  )),
                              const SizedBox(height: 4),
                              Text("$daysJournaled days",
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Word Count",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  )),
                              const SizedBox(height: 4),
                              Text("$totalWordCount words",
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    getDailyQuote(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedItemColor: const Color(0xFF1A237E),
          unselectedItemColor: Colors.grey,
        ),
      ),
      floatingActionButton: !isTodayJournaled()
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1A237E),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/journal');
              },
            )
          : null,
    );
  }
}
