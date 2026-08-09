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
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF1C1C1E),
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
  // 0 set karne se app seedha Videos tab par khulegi
  int _currentIndex = 0; 
  String userName = "Arsalan";
  String selectedClass = "Class 12";
  
  List<Map<String, dynamic>> myNotes = [
    {
      'title': 'Physics: Newton\'s Laws of Motion',
      'content': '1st Law: Inertia, 2nd Law: F=ma, 3rd Law: Action & Reaction.',
      'category': 'Education',
      'time': '2/8/2026',
      'isPinned': true,
    },
    {
      'title': 'Maths: Trigonometry Formulas',
      'content': 'sin²θ + cos²θ = 1, tanθ = sinθ/cosθ...',
      'category': 'Education',
      'time': '1/8/2026',
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
            myNotes.add({
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
          setState(() {
            myNotes.removeAt(index);
          });
        },
      ),
      ProfileScreen(
        name: userName,
        studentClass: selectedClass,
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF121212),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
// ------------------- TAB 1: VIDEOS -------------------
class YouTubeSearchScreen extends StatefulWidget {
  final String userClass;
  const YouTubeSearchScreen({super.key, required this.userClass});

  @override
  State<YouTubeSearchScreen> createState() => _YouTubeSearchScreenState();
}

class _YouTubeSearchScreenState extends State<YouTubeSearchScreen> {
  final String apiKey = 'AIzaSyB56HXfKiXxIGEiNCthtNAMYeNTvBjjMQ4';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _videos = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHomeVideos();
  }

  Future<void> _loadHomeVideos() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _statusMessage = '';
    });
    _fetchAndFilterVideos('${widget.userClass} full syllabus study lectures');
  }

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _statusMessage = '';
    });
    _fetchAndFilterVideos('$query ${widget.userClass} lecture tutorial');
  }

  Future<void> _fetchAndFilterVideos(String searchQuery) async {
    final String cleanQuery = Uri.encodeComponent(searchQuery);
    final String url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=25&q=$cleanQuery&type=video&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawVideos = data['items'] ?? [];

        final blockedKeywords = ['rhyme', 'nursery', 'baby', 'cartoon'];

        final filtered = rawVideos.where((item) {
          final title = (item['snippet']['title'] as String).toLowerCase();
          for (var badWord in blockedKeywords) {
            if (title.contains(badWord)) return false;
          }
          return true;
        }).toList();

        setState(() {
          _videos = filtered.isNotEmpty ? filtered : rawVideos;
          _isLoading = false;
          _statusMessage = _videos.isEmpty ? 'Koi video nahi mili!' : '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'API Limit / Network Error';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _resetToHome)
            : const Icon(Icons.school),
        title: Text('${widget.userClass} Feed 📚'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
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
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: (value) => _searchVideos(value),
              ),
            ),
            const SizedBox(height: 15),
            _isLoading// ------------------- TAB 1: VIDEOS (INFINITE SCROLL ENABLED) -------------------
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

  // Bottom tak pahunchne par automatic agli videos fetch hongi
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
          _statusMessage = _videos.isEmpty ? 'Koi video nahi mili!' : '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _statusMessage = 'API Limit / Network Error';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _resetToHome)
            : const Icon(Icons.school),
        title: Text('${widget.userClass} Feed 📚'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
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
                  contentPadding: const EdgeInsets.all(12),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      thumb,
                                      width: double.infinity,
                                      height: 180,
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
                                          const SizedBox(height: 6),
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
                                              const Icon(Icons.play_circle_fill, color: Colors.redAccent),
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

// ------------------- TAB 2: NATIVE-STYLE NOTES -------------------
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
  String selectedFilter = 'All notes';
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _showNoteDialog({int? editIndex}) {
    final bool isEditing = editIndex != null;
    final titleController = TextEditingController(
      text: isEditing ? widget.notes[editIndex]['title'] : '',
    );
    final contentController = TextEditingController(
      text: isEditing ? widget.notes[editIndex]['content'] : '',
    );
    String category = isEditing ? widget.notes[editIndex]['category'] : 'Education';
    bool isPinned = isEditing ? widget.notes[editIndex]['isPinned'] : false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(isEditing ? 'Edit Note' : 'New Note', style: const TextStyle(color: Colors.white)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Category:', style: TextStyle(color: Colors.grey)),
                    DropdownButton<String>(
                      value: category,
                      dropdownColor: const Color(0xFF2C2C2E),
                      items: ['Education', 'Quick Note']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pin to top:', style: TextStyle(color: Colors.grey)),
                    Switch(
                      value: isPinned,
                      onChanged: (val) => setDialogState(() => isPinned = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
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
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.notes.asMap().entries.where((entry) {
      final note = entry.value;
      final matchesCategory = selectedFilter == 'All notes' || note['category'] == selectedFilter;
      final matchesSearch = searchQuery.isEmpty ||
          note['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          note['content'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final pinnedNotes = filtered.where((e) => e.value['isPinned'] == true).toList();
    final otherNotes = filtered.where((e) => e.value['isPinned'] == false).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white, size: 26),
                        onPressed: () {
                          setState(() {
                            isSearching = !isSearching;
                            if (!isSearching) {
                              searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 26),
                        color: const Color(0xFF2C2C2E),
                        onSelected: (value) {
                          if (value == 'sort') {
                            setState(() {
                              widget.notes.sort((a, b) => a['title'].toString().toLowerCase().compareTo(b['title'].toString().toLowerCase()));
                            });
                          } else if (value == 'clear') {
                            setState(() {
                              widget.notes.clear();
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'sort',
                            child: Text('Sort (A-Z)', style: TextStyle(color: Colors.white)),
                          ),
                          const PopupMenuItem(
                            value: 'clear',
                            child: Text('Delete All Notes', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isSearching)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 10),
              const Text('Notes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${widget.notes.length} notes', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip('All notes'),
                    const SizedBox(width: 8),
                    _buildChip('Quick Note'),
                    const SizedBox(width: 8),
                    _buildChip('Education'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    if (pinnedNotes.isNotEmpty) ...[
                      const Text('Pin', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...pinnedNotes.map((entry) => _buildNoteTile(entry.key, entry.value)),
                      const SizedBox(height: 15),
                    ],
                    if (otherNotes.isNotEmpty) ...[
                      const Text('Other', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...otherNotes.map((entry) => _buildNoteTile(entry.key, entry.value)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3A3A3C),
        shape: const CircleBorder(),
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildChip(String label) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3A3C) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(int originalIndex, Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showNoteDialog(editIndex: originalIndex),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(note['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note['content'],
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
              onPressed: () => widget.onDeleteNote(originalIndex),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- TAB 3: PROFILE -------------------
class ProfileScreen extends StatefulWidget {
  final String name;
  final String studentClass;
  final Function(String, String) onSave;

  const ProfileScreen({super.key, required this.name, required this.studentClass, required this.onSave});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedClass;

  final List<String> classes = ['Class 9', 'Class 10', 'Class 11', 'Class 12', 'Coding', 'NEET/JEE'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _selectedClass = widget.studentClass;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Student Profile 👤'), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedClass,
              dropdownColor: const Color(0xFF1C1C1E),
              decoration: const InputDecoration(labelText: 'Select Class/Goal', border: OutlineInputBorder()),
              items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedClass = val);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  widget.onSave(_nameController.text, _selectedClass);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Updated Successfully! 🎉')),
                  );
                },
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
