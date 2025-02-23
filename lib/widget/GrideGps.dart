import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../detailPost_page.dart';
import 'dart:math' show asin, cos, pow, sin, sqrt;
import 'package:geolocator/geolocator.dart';

class GridGPS extends StatefulWidget {
  final String? searchString;
  const GridGPS({Key? key,this.searchString}) : super(key: key);

  @override
  State<GridGPS> createState() => _GridGPSState();
}

class _GridGPSState extends State<GridGPS> {
  User? user = FirebaseAuth.instance.currentUser;
  final _postRef = FirebaseDatabase.instance.ref().child('postitem');
  Position? currentPosition;
  double userLat = 0.0; // ละติจูดของผู้ใช้ปัจจุบัน
  double userLon = 0.0; // ลองจิจูดของผู้ใช้ปัจจุบัน

  @override
  void initState() {
    super.initState();
    getLocation(); // เรียกเมธอด getLocation() เพื่อรับตำแหน่งปัจจุบันของผู้ใช้
  }

  void getLocation() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (currentPosition != null) {
        setState(() {
          userLat = currentPosition!.latitude;
          userLon = currentPosition!.longitude;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    const R = 6371.0; // รัศมีของโลกในหน่วยกิโลเมตร
    final c = 2 *
        R *
        asin(sqrt(pow(sin((lat2 - lat1) * p / 2), 2) +
            cos(lat1 * p) *
                cos(lat2 * p) *
                pow(sin((lon2 - lon1) * p / 2), 2)));
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _postRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("No data available"),
            );
          }

          DataSnapshot dataSnapshot = snapshot.data!.snapshot;
          Map<dynamic, dynamic>? dataMap = dataSnapshot.value as Map?;

          if (dataMap != null) {
            List<dynamic> filteredData = dataMap.values.where((userData) {
              // Check if the post status is neither 'แลกเปลี่ยนสำเร็จ' nor 'ล้มเหลว'
              bool isPostSuccess =
                  userData['answerStatus'] != 'แลกเปลี่ยนสำเร็จ' &&
                      userData['answerStatus'] != 'ล้มเหลว';
              return isPostSuccess;
            }).toList();

            // Filter data based on search query
            if (widget.searchString != null &&
                widget.searchString!.isNotEmpty) {
              String searchText = widget.searchString!.toLowerCase();
              filteredData = filteredData.where((userData) {
                String itemName = userData['item_name']
                    .toString()
                    .toLowerCase();
                String itemName1 = userData['item_name1']
                    .toString()
                    .toLowerCase();
                String type = userData['type'].toString().toLowerCase();
                return itemName.contains(searchText) ||
                    type.contains(searchText);
              }).toList();
            }

            filteredData.sort((a, b) {
              double distanceA = calculateDistance(
                  userLat, userLon, double.parse(a['latitude']),
                  double.parse(a['longitude']));
              double distanceB = calculateDistance(
                  userLat, userLon, double.parse(b['latitude']),
                  double.parse(b['longitude']));
              return distanceA.compareTo(distanceB);
            });

            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      dynamic userData = filteredData[index];
                      String itemName = userData['item_name'].toString();
                      String itemName1 = userData['item_name1'].toString();
                      String type = userData['type'];
                      String postUid = userData['post_uid'].toString();
                      String latitude = userData['latitude'].toString();
                      String longitude = userData['longitude'].toString();
                      String imageUser = userData['imageUser'];
                      String statusPost = userData['statusPosts'];
                      String userUid = userData['uid'];
                      bool isVip = userData['status_user'] == 'ผู้ใช้พรีเมี่ยม';
                      String textSum1 = itemName + type;
                      String textSum2 = type + itemName;

                      String searchText = widget.searchString?.toLowerCase()
                          .replaceAll(" ", "") ?? "";

                      bool containsSimilarWords = textSum1.contains(
                          searchText) || textSum2.contains(searchText) ||
                          itemName.contains(searchText) ||
                          type.contains(searchText);


                      double postLat = double.parse(latitude);
                      double postLon = double.parse(longitude);

                      double distance =
                      calculateDistance(userLat, userLon, postLat, postLon);

                      List<String> imageUrls =
                      List<String>.from(userData['imageUrls'] ?? []);
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.all(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isVip)
                                      Image.asset('assets/images/vip.png'),
                                    Text(
                                      itemName.length <= 16
                                          ? itemName
                                          : itemName.substring(0, 16) + '...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (imageUrls.isNotEmpty)
                              Center(
                                child: AspectRatio(
                                  aspectRatio: 1 / 1,
                                  child: Image.network(
                                    imageUrls.first,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Center(
                                child: Text(
                                  'แลกเปลี่ยนกับ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 22, 22, 22),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Center(
                                child: Text(
                                  itemName1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            statusPost == 'รอการยืนยัน' ||
                                statusPost == 'ยืนยัน'
                                ? const Center(
                                child: Text('สถานะ: กำลังดำเนินการ'))
                                : Center(
                              child: Text(
                                'สถานะ: $statusPost',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(width: 5),
                                Icon(Icons.room_sharp, size: 15),
                                SizedBox(width: 5),
                                Center(
                                    child: Text(
                                      'ห่างจากคุณ ${distance.toStringAsFixed(
                                          2)} กม.',
                                      style: TextStyle(fontSize: 13.7),
                                    ))
                              ],
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: user?.uid != userUid
                                  ? ElevatedButton(
                                onPressed: () {
                                  Future.delayed(
                                      const Duration(seconds: 1), () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ShowDetailAll(
                                              postUid: postUid,
                                              longti: longitude,
                                              lati: latitude,
                                              imageUser: imageUser,
                                              statusPost: statusPost,
                                            ),
                                      ),
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Theme
                                      .of(context)
                                      .primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Center(
                                    child: Text('รายละเอียด')),
                              )
                                  : const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    'โพสต์ของฉัน',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 340),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text("No data available"),
            );
          }
        },
      ),
    );
  }
}
