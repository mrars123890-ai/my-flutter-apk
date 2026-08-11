import 'dart01:json';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EduProApp());
}

class EduProApp extends StatelessWidget {
  const EduProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduPro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _userName = 'Arsalan';
  String _selectedClass = 'Class 12';
  List<Map<String, String>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndNotes();
  }

  // Load Saved Data from Local Storage
  Future<void> _loadProfileAndNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Arsalan';
      _selectedClass = prefs.getString('selected_class') ?? 'Class 12';
      
      String? notesJson = prefs.getString('saved_notes');
      if (notesJson != null) {
        List<dynamic> decoded = jsonDecode(notesJson);
        _notes = decoded.map((item) => Map<String, String>.from(item)).toList();
      } else {
        _notes = [
          {
            'title': 'Physics: Newton\'s Laws',
            'content': '1st Law: Inertia, 2nd Law: F=ma, 3rd Law: Action & Reaction.',
            'category': 'Education',
            'date': '2026-08-09'
          },
        ];
      }
    });
  }

  // Save Profile Data Locally
  Future<void> _saveProfile(String name, String className) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('selected_class', className);
    setState(() {
      _userName = name;
      _selectedClass = className;
    });
  }

  // Save Notes Locally
  Future<void> _saveNotesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notes', jsonEncode(_notes));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      VideosFeedScreen(selectedClass: _selectedClass),
      NotesScreen(
        notes: _notes,
        onNotesUpdated: () {
          _saveNotesToPrefs();
          setState(() {});
        },
      ),
      ProfileScreen(
        userName: _userName,
        selectedClass: _selectedClass,
        totalNotes: _notes.length,
        onSaveProfile: _saveProfile,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1E1E1E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ----------------- VIDEOS FEED SCREEN -----------------
class VideosFeedScreen extends StatefulWidget {
  final String selectedClass;
  const VideosFeedScreen({super.key, required this.selectedClass});

  @override
  State<VideosFeedScreen> createState() => _VideosFeedScreenState();
}

class _VideosFeedScreenState extends State<VideosFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _videos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVideos(widget.selectedClass);
  }

  @override
  void didUpdateWidget(covariant VideosFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClass != widget.selectedClass) {
      _fetchVideos(widget.selectedClass);
    }
  }

  Future<void> _fetchVideos(String query) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
        'https://invidious.nerdvpn.de/api/v1/search?q=${Uri.encodeComponent(query)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _videos = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EduPro - ${widget.selectedClass} 🎓'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search topic...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _fetchVideos('${widget.selectedClass} ${_searchController.text}');
                    }
                  },
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _fetchVideos('${widget.selectedClass} $value');
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      if (video['type'] != 'video') return const SizedBox.shrink();
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1E1E1E),
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            if (video['videoThumbnails'] != null &&
                                video['videoThumbnails'].isNotEmpty)
                              Image.network(
                                video['videoThumbnails'][0]['url'],
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                video['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                video['author'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// ----------------- NOTES SCREEN -----------------
class NotesScreen extends StatefulWidget {
  final List<Map<String, String>> notes;
  final VoidCallback onNotesUpdated;

  const NotesScreen({super.key, required this.notes, required this.onNotesUpdated});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedCategory = 'All';

  void _addOrEditNote({Map<String, String>? existingNote, int? index}) {
    TextEditingController titleCtrl =
        TextEditingController(text: existingNote?['title'] ?? '');
    TextEditingController contentCtrl =
        TextEditingController(text: existingNote?['content'] ?? '');
    String category = existingNote?['category'] ?? 'Education';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: Text(existingNote == null ? 'New Note 📝' : 'Edit Note 📝'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
            DropdownButton<String>(
              value: category,
              isExpanded: true,
              dropdownColor: const Color(0xFF222222),
              items: ['Education', 'Personal', 'Work'].map((String cat) {
                return DropdownMenuItem<String>(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => category = val);
              },
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                final noteData = {
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'category': category,
                  'date': DateTime.now().toString().split(' ')[0],
                };
                if (index != null) {
                  widget.notes[index] = noteData;
                } else {
                  widget.notes.insert(0, noteData);
                }
                widget.onNotesUpdated();
                Navigator.pop(ctx);
              }
            },
            child: Text(existingNote == null ? 'Save' : 'Update'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredNotes = _selectedCategory == 'All'
        ? widget.notes
        : widget.notes.where((n) => n['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes 📝')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Education', 'Personal', 'Work'].map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(child: Text('No notes available'))
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, i) {
                      final item = filteredNotes[i];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(item['title'] ?? ''),
                          subtitle: Text('${item['content']}\n${item['date']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () =>
                                    _addOrEditNote(existingNote: item, index: i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  widget.notes.removeAt(i);
                                  widget.onNotesUpdated();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// ----------------- PROFILE SCREEN -----------------
class ProfileScreen extends StatefulWidget {
  final String userName;
  final String selectedClass;
  final int totalNotes;
  final Function(String, String) onSaveProfile;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.selectedClass,
    required this.totalNotes,
    required this.onSaveProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedClass;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _selectedClass = widget.selectedClass;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile 👤')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.selectedClass,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('${widget.totalNotes}', 'Total Notes'),
                  _buildStatCard(widget.selectedClass, 'Active Syllabus'),
                ],
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ['Class 9', 'Class 10', 'Class 11', 'Class 12'].contains(_selectedClass)
                    ? _selectedClass
                    : 'Class 12',
                items: ['Class 9', 'Class 10', 'Class 11', 'Class 12'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _selectedClass = val!),
                decoration: const InputDecoration(
                  labelText: 'Select Class',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  widget.onSaveProfile(_nameController.text, _selectedClass);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('EduPro profile saved successfully!')),
                  );
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
