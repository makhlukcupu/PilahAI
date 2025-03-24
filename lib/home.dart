import 'package:flutter/material.dart';

class Home extends StatefulWidget{
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0x00e8ffe8),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 50),
          Text('Kategori Sampah',
            style: TextStyle(
                color: Color(0x00000000),
                fontSize:20 ),
          ),
          SizedBox(height: 50)


        ],
      ),
      )
    );
  }
}