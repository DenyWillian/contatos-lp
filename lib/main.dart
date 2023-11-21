import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class Contact {
  int? id;
  String name;
  String phoneNumber;
  String email;

  Contact({this.id, required this.name, required this.phoneNumber, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  static Contact fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Contatos',
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  static const IconData _contactsIcon = Icons.people;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Início'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/foto.png', width: 150, height: 150),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactsScreen()),
                );
              },
              child: ElevatedButton.icon(
                onPressed: null,
                icon: Icon(_contactsIcon),
                label: Text('Contatos Novos'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Database _database;
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _getContacts();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'contacts_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phoneNumber TEXT, email TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> _getContacts() async {
    final List<Map<String, dynamic>> maps = await _database.query('contacts');
    contacts = List.generate(maps.length, (index) {
      return Contact.fromMap(maps[index]);
    });
    setState(() {});
  }

  Future<void> _insertContact(Contact contact) async {
    await _database.insert('contacts', contact.toMap());
  }

  Future<void> _deleteContact(int? id) async {
    if (id != null) {
      print("Deleting contact with ID: $id");
      await _database.delete('contacts', where: 'id = ?', whereArgs: [id]);
      setState(() {
        contacts.removeWhere((contact) => contact.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contatos'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contacts[index].name),
            subtitle: Text(contacts[index].phoneNumber),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailsScreen(contacts[index]),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                int? contactId = contacts[index].id;
                if (contactId != null) {
                  _deleteContact(contactId);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddContactScreen()),
          ).then((newContact) {
            if (newContact != null) {
              _insertContact(newContact);
              setState(() {
                contacts.add(newContact);
              });
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddContactScreen extends StatefulWidget {
  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Contato'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String name = nameController.text;
                String phoneNumber = phoneNumberController.text;
                String email = emailController.text;

                if (name.isNotEmpty && phoneNumber.isNotEmpty && email.isNotEmpty) {
                  Contact newContact = Contact(
                    name: name,
                    phoneNumber: phoneNumber,
                    email: email,
                  );
                  Navigator.pop(context, newContact);
                }
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailsScreen extends StatelessWidget {
  final Contact contact;

  ContactDetailsScreen(this.contact);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Contato'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailRow('Nome', contact.name),
            _buildDetailRow('Telefone', contact.phoneNumber),
            _buildDetailRow('E-mail', contact.email),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: const Color.fromARGB(221, 255, 255, 255),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
