import 'package:flutter/material.dart';

Widget buildListTile(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {},
      ),
    );
  }
