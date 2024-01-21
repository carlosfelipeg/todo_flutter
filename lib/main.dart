import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: FutureBuilder(
        future: apiService.getAllTodos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final todos = snapshot.data;
            return ListView.builder(
              itemCount: (todos?['completed']?.length ?? 0) + (todos?['pending']?.length ?? 0),
              itemBuilder: (context, index) {
                final todo = index < (todos?['completed']?.length ?? 0)
                    ? todos?['completed']?[index]
                    : todos?['pending']?[index - (todos?['completed']?.length ?? 0)];

                return buildTodoItem(todo);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a new screen for creating a todo
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTodoScreen(apiService: apiService),
            ),
          ).then((value) {
            // Refresh the todo list after creating a new todo
            if (value != null && value) {
              setState(() {});
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget buildTodoItem(Map<String, dynamic>? todo) {
    return ListTile(
      title: Text(todo?['title'] ?? ''),
      subtitle: Text(todo?['description'] ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: todo?['completed'] ?? false,
            onChanged: (value) async {
              if (todo != null) {
                await apiService.updateTodo(todo['id'], {'completed': value});
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              if (todo != null) {
                // Navigate to a screen for editing the todo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTodoScreen(
                      apiService: apiService,
                      todoId: todo['id'],
                      currentTitle: todo['title'],
                      currentDescription: todo['description'],
                    ),
                  ),
                ).then((value) {
                  // Refresh the todo list after editing the todo
                  if (value != null && value) {
                    setState(() {});
                  }
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              if (todo != null) {
                _deleteTodoDialog(context, todo['id']);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTodoDialog(BuildContext context, int todoId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Todo"),
          content: Text("Are you sure you want to delete this todo?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Call the deleteTodo function here
                  await apiService.deleteTodo(todoId);
                  // Refresh the todo list after deletion
                  setState(() {});
                } catch (e) {
                  // Handle error
                  print("Error deleting todo: $e");
                }
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}

class CreateTodoScreen extends StatelessWidget {
  final ApiService apiService;

  CreateTodoScreen({required this.apiService});

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Todo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Create the new todo
                await apiService.createTodo({
                  'title': titleController.text,
                  'description': descriptionController.text,
                });

                // Return to the previous screen with a flag indicating success
                Navigator.pop(context, true);
              },
              child: Text('Create Todo'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTodoScreen extends StatelessWidget {
  final ApiService apiService;
  final int todoId;
  final String currentTitle;
  final String currentDescription;

  EditTodoScreen({
    required this.apiService,
    required this.todoId,
    required this.currentTitle,
    required this.currentDescription,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController descriptionController = TextEditingController(text: currentDescription);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Todo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Update the todo
                await apiService.updateTodo(todoId, {
                  'title': titleController.text,
                  'description': descriptionController.text,
                });

                // Return to the previous screen with a flag indicating success
                Navigator.pop(context, true);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api/todos';
  static const String user = 'admin';
  static const String password = 'admin';

  Future<Map<String, dynamic>> getAllTodos() async {
    final response = await http.get(
        Uri.parse('$baseUrl/all_todos'),
        headers: {
          'Authorization': 'Basic '+ base64.encode(utf8.encode('$user:$password')),
          'Content-Type': 'application/json'
        },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load todos');
    }
  }

  Future<Map<String, dynamic>> updateTodo(int id, Map<String, dynamic> todoData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update'),
      headers: {
        'Authorization': 'Basic '+ base64.encode(utf8.encode('$user:$password')),
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'id': id, 'todo': todoData}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update todo');
    }
  }

  Future<Map<String, dynamic>> createTodo(Map<String, dynamic> todoData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {
        'Authorization': 'Basic '+ base64.encode(utf8.encode('$user:$password')),
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'todo': todoData}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create todo');
    }
  }

  Future<Map<String, dynamic>> deleteTodo(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/destroy'),
      headers: {
        'Authorization': 'Basic '+ base64.encode(utf8.encode('$user:$password')),
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete todo');
    }
  }
}

