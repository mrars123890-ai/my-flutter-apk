import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        cardColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1C1C1E),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ------------------- MAIN NAVIGATION -------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String userName = "Student";
  String selectedClass = "Class 12";

  List<Map<String, dynamic>> myNotes = [
    {
      'title': 'Physics: Newton\'s Laws of Motion',
      'content': '1st Law: Inertia, 2nd Law: F=ma, 3rd Law: Action & Reaction.',
      'category': 'Education',
      'time': '2026-08-09',
      'isPinned': true,
    },
    {
      'title': 'Chemistry Formulae',
      'content': 'Organic reactions summary and important equations.',
      'category': 'Education',
      'time': '2026-08-08',
      'isPinned': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      YouTubeSearchScreen(userClass: selectedClass),
      NativeNotesScreen(
        notes: myNotes,
        onAddNote: (title, content, category, isPinned) {
          setState(() {
            final DateTime dt = DateTime.now();
            myNotes.insert(0, {
              'title': title,
              'content': content,
              'category': category,
              'time': '${dt.day}/${dt.month}/${dt.year}',
              'isPinned': isPinned,
            });
          });
        },
        onEditNote: (index, title, content, category, isPinned) {
          setState(() {
            final DateTime dt = DateTime.now();
            myNotes[index] = {
              'title': title,
              'content': content,
              'category': category,
              'time': '${dt.day}/${dt.month}/${dt.year}',
              'isPinned': isPinned,
            };
          });
        },
        onDeleteNote: (index) {
          setState(() => myNotes.removeAt(index));
        },
      ),
      ProfileScreen(
        name: userName,
        studentClass: selectedClass,
        totalNotes: myNotes.length,
        onSave: (newName, newClass) {
          setState(() {
            userName = newName;
            selectedClass = newClass;
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF121212),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt_rounded), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------- TAB 1: VIDEOS (INFINITE SCROLL) -------------------
class YouTubeSearchScreen extends StatefulWidget {
  final String userClass;
  const YouTubeSearchScreen({super.key, required this.userClass});

  @override
  State<YouTubeSearchScreen> createState() => _YouTubeSearchScreenState();
}

class _YouTubeSearchScreenState extends State<YouTubeSearchScreen> {
  final String apiKey = 'AIzaSyB56HXfKiXxIGEiNCthtNAMYeNTvBjjMQ4';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _videos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String _statusMessage = '';
  String? _nextPageToken;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHomeVideos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _nextPageToken != null) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadHomeVideos() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _statusMessage = '';
      _videos.clear();
      _nextPageToken = null;
    });
    _currentQuery = '${widget.userClass} full syllabus study lectures';
    await _fetchAndFilterVideos(_currentQuery);
  }

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _statusMessage = '';
      _videos.clear();
      _nextPageToken = null;
    });
    _currentQuery = '$query ${widget.userClass} lecture tutorial';
    await _fetchAndFilterVideos(_currentQuery);
  }

  Future<void> _loadMoreVideos() async {
    if (_nextPageToken == null) return;
    setState(() => _isLoadingMore = true);
    await _fetchAndFilterVideos(_currentQuery, isNextPage: true);
  }

  Future<void> _fetchAndFilterVideos(String searchQuery, {bool isNextPage = false}) async {
    final String cleanQuery = Uri.encodeComponent(searchQuery);
    String url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=20&q=$cleanQuery&type=video&key=$apiKey';

    if (_nextPageToken != null) {
      url += '&pageToken=$_nextPageToken';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawVideos = data['items'] ?? [];
        _nextPageToken = data['nextPageToken'];

        final blockedKeywords = ['rhyme', 'nursery', 'baby', 'cartoon'];

        final filtered = rawVideos.where((item) {
          final title = (item['snippet']['title'] as String).toLowerCase();
          for (var badWord in blockedKeywords) {
            if (title.contains(badWord)) return false;
          }
          return true;
        }).toList();

        final newResults = filtered.isNotEmpty ? filtered : rawVideos;

        setState(() {
          if (isNextPage) {
            _videos.addAll(newResults);
          } else {
            _videos = newResults;
          }
          _isLoading = false;
          _isLoadingMore = false;
          _statusMessage = _videos.isEmpty ? 'No videos found!' : '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _statusMessage = 'API Limit or Network Error';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _statusMessage = 'Connection Error';
      });
    }
  }

  void _resetToHome() {
    _searchController.clear();
    _loadHomeVideos();
  }

  Future<void> _openVideo(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        elevation: 0,
        leading: _isSearching
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _resetToHome)
            : const Icon(Icons.school, color: Colors.blueAccent),
        title: Text('${widget.userClass} Feed 📚', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D0D0D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search topic (e.g. Physics, Chemistry)...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () => _searchVideos(_searchController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: (value) => _searchVideos(value),
              ),
            ),
            const SizedBox(height: 15),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)))
                : _statusMessage.isNotEmpty
                    ? Expanded(
                        child: Center(
                          child: Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _videos.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _videos.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                              );
                            }

                            final video = _videos[index]['snippet'];
                            final videoId = _videos[index]['id']?['videoId'] ?? '';
                            final title = video['title'] ?? '';
                            final channel = video['channelTitle'] ?? '';
                            final thumb = video['thumbnails']?['medium']?['url'] ?? '';

                            return InkWell(
                              onTap: () => _openVideo(videoId),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      thumb,
                                      width: double.infinity,
                                      height: 190,
                                      fit: BoxFit.cover,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  channel,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

// ------------------- TAB 2: STYLISH NOTES -------------------
class NativeNotesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  final Function(String, String, String, bool) onAddNote;
  final Function(int, String, String, String, bool) onEditNote;
  final Function(int) onDeleteNote;

  const NativeNotesScreen({
    super.key,
    required this.notes,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  @override
  State<NativeNotesScreen> createState() => _NativeNotesScreenState();
}

class _NativeNotesScreenState extends State<NativeNotesScreen> {
  String selectedFilter = 'All';
  final List<String> categories = ['All', 'Education', 'Personal', 'Work'];

  void _showNoteDialog({int? editIndex}) {
    final bool isEditing = editIndex != null;
    final titleController = TextEditingController(text: isEditing ? widget.notes[editIndex]['title'] : '');
    final contentController = TextEditingController(text: isEditing ? widget.notes[editIndex]['content'] : '');
    String category = isEditing ? widget.notes[editIndex]['category'] : 'Education';
    bool isPinned = isEditing ? widget.notes[editIndex]['isPinned'] : false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Edit Note ✏️' : 'New Note 📝', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Content', labelStyle: TextStyle(color: Colors.grey)),
                  maxLines: 4,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.grey)),
                  items: ['Education', 'Personal', 'Work']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isPinned,
                      activeColor: Colors.blueAccent,
                      onChanged: (val) => setDialogState(() => isPinned = val!),
                    ),
                    const Text('Pin this note', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  if (isEditing) {
                    widget.onEditNote(editIndex, titleController.text, contentController.text, category, isPinned);
                  } else {
                    widget.onAddNote(titleController.text, contentController.text, category, isPinned);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = selectedFilter == 'All'
        ? widget.notes
        : widget.notes.where((n) => n['category'] == selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Notes 📝', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            // Category Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) {
                  final isSelected = selectedFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: const Color(0xFF1C1C1E),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                      onSelected: (_) => setState(() => selectedFilter = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(child: Text('No notes available', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        final originalIndex = widget.notes.indexOf(note);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                            border: note['isPinned'] ? Border.all(color: Colors.blueAccent.withOpacity(0.6), width: 1) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (note['isPinned']) const Icon(Icons.push_pin, color: Colors.blueAccent, size: 16),
                                      if (note['isPinned']) const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(note['category'], style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
                                        onPressed: () => _showNoteDialog(editIndex: originalIndex),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        onPressed: () => widget.onDeleteNote(originalIndex),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(note['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(note['content'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(note['time'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ------------------- TAB 3: STYLISH PROFILE -------------------
class ProfileScreen extends StatefulWidget {
  final String name;
  final String studentClass;
  final int totalNotes;
  final Function(String, String) onSave;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.studentClass,
    required this.totalNotes,
    required this.onSave,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedClass;

  final List<String> classesList = ['Class 9', 'Class 10', 'Class 11', 'Class 12'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _selectedClass = widget.studentClass;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Profile 👤', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 50, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.studentClass, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),

            // Stats Cards Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text('${widget.totalNotes}', style: const TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Total Notes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(_selectedClass, style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Active Syllabus', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Form Inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    dropdownColor: const Color(0xFF2C2C2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Select Class',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedClass = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onSave(_nameController.text, _selectedClass);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile details updated successfully!')),
                  );
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
