import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:swapitem/offerCome2.dart';
import 'package:swapitem/widget/chat_detail.dart';
import 'package:swapitem/widget/offer_imageshow.dart';

import 'HisMake2.dart';
//หน้าประวัติการโพสต์

class His_Makeoffer extends StatefulWidget {
  const His_Makeoffer({Key? key}) : super(key: key);

  @override
  State<His_Makeoffer> createState() => _His_MakeofferState();
}

class _His_MakeofferState extends State<His_Makeoffer> {
  late User _user;
  double? latitude;
  double? longitude;
  late DatabaseReference _offerRef;
  List<Map<dynamic, dynamic>> postsList = [];
  int _selectedIndex = -1;
  Map<dynamic, dynamic>? selectedPost;
  late GoogleMapController mapController;
  int? mySlideindex;
  List<String> image_post = [];
  @override
  //เรียงข้องมูลโดยที่ใน firbasr มี "timestamp" เป็นตัวเลือกให้คุ
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _offerRef = FirebaseDatabase.instance.ref().child('offer');
    selectedPost = null;

    _offerRef.orderByChild('uid').equalTo(_user.uid).onValue.listen((event) {
      postsList.clear();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          if (true) {
            postsList.add(value);
          }
        });

        // Sort postsList by 'timestamp' in descending order
        postsList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        if (postsList.isNotEmpty) {
          setState(() {
            selectedPost = postsList.first;
            _selectedIndex = 0;
          });
        }
      }
    }).onError((error) {
      print("Error fetching data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ข้อเสนอที่เข้ามา"),
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
        body: StreamBuilder(
          stream: _offerRef.orderByChild('uid').equalTo(_user.uid).onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasData &&
                snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);

              if (true) {
                // Return content when there are posts with "รอการยืนยัน" status
                return Column(
                  children: [
                    selectedPost != null
                        ? Expanded(
                            child: ListView(
                              children: [
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 50,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: postsList
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                int idx = entry.key;
                                                Map<dynamic, dynamic> postData =
                                                    entry.value;
                                                image_post = List<String>.from(
                                                    selectedPost!['imageUrls']);
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4.0),
                                                  child:
                                                      buildCircularNumberButton(
                                                          idx, postData),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          const Divider(),
                                          const Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: Text(
                                              'โพสต์ของคุณ',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          ImageGalleryWidget(
                                            imageUrls: image_post,
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.tag,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'หมายเลขโพสต์ : ' +
                                                    selectedPost!['uid'],
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.date_range,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "วันที่ : ${DateFormat('dd MMMM yyyy', 'th_TH').format(DateTime.parse(selectedPost!['date']))}",
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .punch_clock, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                                color: Colors
                                                    .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                              ),
                                              Text(
                                                " เวลา :" +
                                                    selectedPost!['time'] +
                                                    ' น.',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 2,
                                                right: 15,
                                                top: 10,
                                                bottom: 10),
                                            child: Container(
                                              width: 437,
                                              height: 360,
                                              decoration: ShapeDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment(0.00, -1.00),
                                                  end: Alignment(0, 1),
                                                  colors: [
                                                    Color(0x60414DB3),
                                                    Color(0x008B47C1)
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(19),
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(11.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'ชื่อสิ่งของ : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'หมวดหมู่ : ' +
                                                          selectedPost!['uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'ยี่ห้อ : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'รุ่น : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'รายละเอียด : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Center(
                                                        child: Image.asset(
                                                      'assets/images/swap.png',
                                                      width: 20,
                                                    )),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                      'ชื่อสิ่งของ : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'ยี่ห้อ : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'รุ่น : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      'รายละเอียด : ' +
                                                          selectedPost![
                                                              'uid'],
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          const Divider(),
                                          His_Make_off2(
                                              postUid:
                                                  selectedPost!['offer_uid']),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const Column(
                            children: [
                              CircularProgressIndicator(),
                              Text('กำลังโหลด..'),
                            ],
                          ),
                  ],
                ); //ทำงานเมื่อมีข้อมูล และ ['statusPosts'] == "รอการยืนยัน"
              } else {
                // Return content when there are no posts with "รอการยืนยัน" status
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/256/11191/11191755.png',
                        width: 100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ไม่มีข้อเสนอที่เข้ามา',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                );
              }
            } else {
              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://cdn-icons-png.flaticon.com/256/11191/11191755.png',
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ไม่มีข้อเสนอที่เข้ามา',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              );
            }
          }, //gg
        ),
      ),
    );
  }

  Widget buildCircularNumberButton(int index, Map<dynamic, dynamic> postData) {
    print("look at me" + selectedPost.toString());
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index; // Update the selected index
          selectedPost = postData; // Update the selected payment data
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Colors.blue
              : Colors.grey, // Highlight if selected
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
