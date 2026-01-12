import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';

class TownSquareView extends StatefulWidget {
  const TownSquareView({super.key});

  @override
  State<TownSquareView> createState() => _TownSquareViewState();
}

class _TownSquareViewState extends State<TownSquareView> {
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Jane Smith',
      'avatar': Icons.person,
      'time': '2 hours ago',
      'content':
          'Just attended the city council meeting. Great discussion on the new park initiative! 🌳',
      'likes': 24,
      'comments': 5,
      'isLiked': false,
    },
    {
      'author': 'Mike Johnson',
      'avatar': Icons.person_outline,
      'time': '5 hours ago',
      'content':
          'Reminder: Town hall meeting tomorrow at 6 PM. Let\'s make our voices heard!',
      'likes': 42,
      'comments': 12,
      'isLiked': true,
    },
    {
      'author': 'Sarah Williams',
      'avatar': Icons.person_2,
      'time': '1 day ago',
      'content':
          'The new community center is looking amazing! Can\'t wait for the grand opening next month.',
      'likes': 67,
      'comments': 18,
      'isLiked': false,
    },
    {
      'author': 'David Brown',
      'avatar': Icons.person_3,
      'time': '2 days ago',
      'content':
          'Does anyone know when the road construction on Main Street will be completed?',
      'likes': 15,
      'comments': 8,
      'isLiked': false,
    },
  ];

  void _toggleLike(int index) {
    setState(() {
      _posts[index]['isLiked'] = !_posts[index]['isLiked'];
      _posts[index]['likes'] += _posts[index]['isLiked'] ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Town Square'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search posts')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryDark,
                        child: Icon(
                          post['avatar'],
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              post['time'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('More options')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Post Content
                  Text(
                    post['content'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  // Post Actions
                  Row(
                    children: [
                      // Like Button
                      InkWell(
                        onTap: () => _toggleLike(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                post['isLiked']
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post['isLiked'] ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post['likes']}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Comment Button
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('View ${post['comments']} comments'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post['comments']}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Share Button
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share post')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreatePostDialog();
        },
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: AppColors.primaryLight),
        label: const Text(
          'New Post',
          style: TextStyle(color: AppColors.primaryLight),
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final TextEditingController postController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Post'),
        content: TextField(
          controller: postController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (postController.text.isNotEmpty) {
                setState(() {
                  _posts.insert(0, {
                    'author': 'You',
                    'avatar': Icons.person,
                    'time': 'Just now',
                    'content': postController.text,
                    'likes': 0,
                    'comments': 0,
                    'isLiked': false,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.primaryLight,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
