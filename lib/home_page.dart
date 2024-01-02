import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swapitem/registerVip_page.dart';
import 'package:swapitem/buildPost_page.dart';
import 'package:swapitem/widget/grid_view.dart';
import 'package:swapitem/notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User _user;
  late DatabaseReference _userRef;
  String? _searchString;
  TextEditingController searchController = TextEditingController();
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _userRef = FirebaseDatabase.instance.ref().child('users').child(_user.uid);
  }

  void handleSearch() {
    setState(() {
      _searchString = searchController.text.trim().isEmpty
          ? null
          : searchController.text.trim().toLowerCase();
    });
  }

Stream<int> getUnreadNotificationCountStream() {
  var notificationCollection =
      FirebaseFirestore.instance.collection('notifications');

  return notificationCollection
      .where('userId', isEqualTo: _user.uid) // Filter by current user ID
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

Future<void> markNotificationsAsRead() async {
  var notificationCollection =
      FirebaseFirestore.instance.collection('notifications');
  var batch = FirebaseFirestore.instance.batch();

  var querySnapshot = await notificationCollection
      .where('userId', isEqualTo: _user.uid) // Filter by current user ID
      .where('read', isEqualTo: false)
      .get();

  for (var doc in querySnapshot.docs) {
    batch.update(doc.reference, {'read': true});
  }

  await batch.commit();
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: StreamBuilder<int>(
                stream: getUnreadNotificationCountStream(),
                builder: (context, snapshot) {
                  int notificationCount = snapshot.data ??
                      0; // Use null-aware operator to handle null data
                  return Stack(
                    children: <Widget>[
                      const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          // Badge position
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              onPressed: () async {
                await markNotificationsAsRead();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationD(),
                  ),
                );
              },
            ),
          ],
          toolbarHeight: 40,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image 40.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: StreamBuilder(
            stream: _userRef.onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(height: 350),
                      CircularProgressIndicator(),
                      Text('กำลังโหลดข้อมูล...')
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                Map dataUser = dataSnapshot.value as Map;
                String postCount = dataUser['postCount'].toString();
                String makeofferCount = dataUser['makeofferCount'].toString();

                return Column(
                  children: [
                    //ส่วนบนของหน้าหลัก
                    buildUserProfileSection(
                        dataUser, postCount, makeofferCount),
                    const Divider(),
                    searchItem(), //ค้นหา
                    showItemSearch(), //แสดงสิ่งของที่ค้นหา
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildUserProfileSection(
      Map dataUser, String postCount, String makeofferCount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: ClipRRect(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          width: 1.0,
                          color: Colors.black,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'โควตาการโพสต์ ${postCount}/5 เดือน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: ClipRRect(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          width: 1.0,
                          color: Colors.black,
                        ), // เส้นขอบ
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'โควตาการยื่นข้อเสนอ ${makeofferCount}/5 เดือน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Payment(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              width: 1.0,
                              color: Colors.black,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(
                              spacing: 5.0, // ระยะห่างระหว่างไอคอนและข้อความ
                              children: [
                                Image.asset('assets/images/vip.png'),
                                Text(
                                  'เติม VIP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Padding(
                          padding: EdgeInsets.only(top: 6.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.create,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => NewPost(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              side: const BorderSide(
                                width: 1.0,
                                color: Colors.black,
                              ), // เส้นขอบ
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 20.0,
                              ), // ระยะห่างภายในปุ่ม
                              backgroundColor: Colors.red, // สีข้างใน
                            ),
                            label: const Text(
                              'สร้างโพสต์',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                alignment: Alignment.topCenter,
                child: ClipOval(
                  child: Image.network(
                    dataUser['image_user'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dataUser['username'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget showItemSearch() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: SizedBox(
            height: 600,
            width: double.infinity,
            child: ShowAllPostItem(searchString: _searchString)),
      ),
    );
  }

  Widget searchItem() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(width: 0.8),
                ),
                hintText: "ค้นหา",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchController.clear();
                _searchString = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: handleSearch,
          ),
        ],
      ),
    );
  }
}
