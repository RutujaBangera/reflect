import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});
  @override
  JournalPageState createState() => JournalPageState();
}

class JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> journalEntries = [];
  int _selectedIndex = 2; // Set to 2 for journal tab
  String currentUsername = '';
  bool _isLoading = true;

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
        _loadJournalEntries();
      } else {
        // No user logged in, redirect to login
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  // Load journal entries from Firestore
  Future<void> _loadJournalEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('journal_entries')
          .where('user', isEqualTo: currentUsername)
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> entries = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        entries.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'entry': data['entry'] ?? '',
          'date': data['date'],
          'mood': data['mood'] ?? 'Happy', // ← Get actual mood from Firestore
        });
      }

      setState(() {
        journalEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading journal entries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('journal_entries')
          .doc(entryId)
          .delete();
      _loadJournalEntries(); // Refresh entries
    } catch (e) {
      print('Error deleting entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting entry: $e')),
      );
    }
  }

  void _addNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEditor(
          currentUsername: currentUsername,
          onSave: (String title, String content, String date, String mood) {
            _loadJournalEntries(); // Reload entries after saving
          },
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/calendar');
    } else if (index == 2) {
      // Already on journal page
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text("My Journal", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJournalEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : journalEntries.isEmpty
              ? const Center(
                  child: Text('No journal entries yet. Tap + to add one!',
                      style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: journalEntries.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalEditor(
                              id: journalEntries[index]['id'],
                              title: journalEntries[index]['title'],
                              content: journalEntries[index]['entry'],
                              date: journalEntries[index]['date'],
                              mood: journalEntries[index]['mood'],
                              currentUsername: currentUsername,
                              onSave: (title, content, date, mood) {
                                _loadJournalEntries(); // Reload entries after saving
                              },
                            ),
                          ),
                        );
                      },
                      child: JournalEntry(
                        title: journalEntries[index]['title'],
                        content: journalEntries[index]['entry'],
                        date: journalEntries[index]['date'],
                        mood: journalEntries[index]['mood'],
                        onDelete: () =>
                            _deleteEntry(journalEntries[index]['id']),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: _addNewEntry,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white, // Change to your desired background color
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
    );
  }
}

class JournalEntry extends StatelessWidget {
  final String title;
  final String content;
  final dynamic date;
  final String mood;
  final VoidCallback onDelete;

  const JournalEntry({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    if (date is Timestamp) {
      formattedDate = DateFormat('d MMM').format(date.toDate());
    } else {
      formattedDate = date.toString();
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(
              left: 12.0), // Optional: adds a little spacing
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1A237E),
              child: Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Mood: $mood',
                style: TextStyle(
                    color: mood == 'Happy'
                        ? Colors.green
                        : mood == 'Sad'
                            ? Colors.blue
                            : mood == 'Angry'
                                ? Colors.red
                                : Colors.grey,
                    fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class JournalEditor extends StatefulWidget {
  final String? id;
  final String? title;
  final String? content;
  final dynamic date;
  final String? mood;
  final String currentUsername;
  final Function(String, String, String, String) onSave;

  const JournalEditor({
    super.key,
    this.id,
    this.title,
    this.content,
    this.date,
    this.mood,
    required this.currentUsername,
    required this.onSave,
  });

  @override
  JournalEditorState createState() => JournalEditorState();
}

class JournalEditorState extends State<JournalEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _date;
  double _moodValue = 4; // Default to 'Happy'
  bool _isSaving = false;

  final List<String> _moods = [
    'Angry',
    'Sad',
    'Neutral',
    'Tired',
    'Happy',
    'Excited'
  ];

  final Map<int, Color> _moodColors = {
    0: Colors.red, // Angry
    1: Colors.blue, // Sad
    2: Color(0xff888888), // Neutral
    3: Colors.purple, // Tired
    4: Colors.green, // Happy
    5: Color(0xffebd408), // Excited
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? 'New Entry');
    _contentController = TextEditingController(text: widget.content ?? '');

    if (widget.date is Timestamp) {
      _date = widget.date.toDate();
    } else {
      _date = DateTime.now();
    }

    // Convert existing mood to slider value
    if (widget.mood != null) {
      _moodValue = _moods.indexOf(widget.mood!).toDouble();
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      CollectionReference journalCollection =
          FirebaseFirestore.instance.collection('journal_entries');

      if (widget.id != null) {
        // Update existing entry
        await journalCollection.doc(widget.id).update({
          'title': _titleController.text,
          'entry': _contentController.text,
          'mood': _moods[_moodValue.toInt()], // Save selected mood
          'lastEdited': Timestamp.now(),
        });
      } else {
        // Create new entry
        await journalCollection.add({
          'title': _titleController.text,
          'entry': _contentController.text,
          'date': Timestamp.now(),
          'mood': _moods[_moodValue.toInt()], // Save selected mood
          'user': widget.currentUsername,
        });
      }

      widget.onSave(
        _titleController.text,
        _contentController.text,
        DateFormat('d MMMM yyyy').format(_date),
        _moods[_moodValue.toInt()],
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving journal entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving journal entry: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: Text(
          widget.id == null ? 'New Entry' : 'Edit Entry',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveEntry,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Date display
            Text(
              DateFormat('d MMMM yyyy').format(_date),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Mood Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mood:', style: TextStyle(fontSize: 16)),
                Text(
                  _moods[_moodValue.toInt()], // Display selected mood name
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _moodColors[_moodValue.toInt()],
                  ),
                ),
              ],
            ),
            Slider(
              value: _moodValue,
              min: 0,
              max: 5,
              divisions: 5,
              label: _moods[_moodValue.toInt()],
              activeColor: _moodColors[_moodValue.toInt()],
              onChanged: (double value) {
                setState(() {
                  _moodValue = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Journal content
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
