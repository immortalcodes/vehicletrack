import 'dart:async';
import 'package:tracker/MapPage.dart';
import 'dart:io' show Platform;
import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:workmanager/workmanager.dart';




const fetchBackground = "fetchBackground";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackground:
        // Code to run in background
        break;
    }
    return Future.value(true);
  });}




/// Defines the main theme color.
final MaterialColor themeMaterialColor =
BaseflowPluginExample.createMaterialColor(
    Color.fromARGB(255, 255, 114, 49));

void main() {
  runApp(const GeolocatorWidget());
}

/// Example [Widget] showing the functionalities of the geolocator plugin
class GeolocatorWidget extends StatefulWidget {
  /// Creates a new GeolocatorWidget.
  const GeolocatorWidget({Key? key}) : super(key: key);

  /// Utility method to create a page with the Baseflow templating.
  static ExamplePage createPage() {
    return ExamplePage(
        Icons.location_on, (context) => const GeolocatorWidget());
  }

  @override
  _GeolocatorWidgetState createState() => _GeolocatorWidgetState();
}

class _GeolocatorWidgetState extends State<GeolocatorWidget> {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  double distance = 0;
  bool startposition = false;
  late String previousposi ;
  List<LatLng> latLen = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;

  @override
  void initState() {
    super.initState();
    _toggleServiceStatusStream();
  }

  PopupMenuButton _createActions() {
    return PopupMenuButton(
      elevation: 40,
      onSelected: (value) async {
        switch (value) {
          case 1:
            _getLocationAccuracy();
            break;
          case 2:
            _requestTemporaryFullAccuracy();
            break;
          case 3:
            _openAppSettings();
            break;
          case 4:
            _openLocationSettings();
            break;
          case 5:
            setState(_positionItems.clear);
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        if (Platform.isIOS)
          const PopupMenuItem(
            child: Text("Get Location Accuracy"),
            value: 1,
          ),
        if (Platform.isIOS)
          const PopupMenuItem(
            child: Text("Request Temporary Full Accuracy"),
            value: 2,
          ),
        const PopupMenuItem(
          child: Text("Open App Settings"),
          value: 3,
        ),
        if (Platform.isAndroid || Platform.isWindows)
          const PopupMenuItem(
            child: Text("Open Location Settings"),
            value: 4,
          ),
        const PopupMenuItem(
          child: Text("Clear"),
          value: 5,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox(
      height: 10,
    );

    return BaseflowPluginExample(
        pluginName: '',
        githubURL: 'https://github.com/immortalcodes',
        pubDevURL: '',
        appBarActions: [
          _createActions()
        ],
        pages: [
          ExamplePage(
            Icons.fire_truck,
                (context) => Scaffold(
              appBar: AppBar(
        title: const Text('Vehicle Tracking Application'),
      ),
              backgroundColor: Color.fromARGB(255, 230, 250, 255),
              body: ListView.builder(
                itemCount: _positionItems.length,
                itemBuilder: (context, index) {
                  final positionItem = _positionItems[index];

                  if (positionItem.type == _PositionItemType.log) {
                    return ListTile(
                      title: Text(positionItem.displayValue+"\n Distance Covered : "+distance.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 215, 157, 21),
                            fontWeight: FontWeight.bold,
                          )),
                    );
                  } else {
                    return Card(
                      child: ListTile(
                        tileColor: themeMaterialColor,
                        title: Text(
                          positionItem.displayValue,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
              ),
              floatingActionButton: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: "btn3",
                    child: (_positionStreamSubscription == null ||
                        _positionStreamSubscription!.isPaused)
                        ? const Icon(Icons.play_arrow)
                        : const Icon(Icons.pause),
                    onPressed: () {
                      positionStreamStarted = !positionStreamStarted;
                      _toggleListening();
                    },
                    tooltip: (_positionStreamSubscription == null)
                        ? 'Start position updates'
                        : _positionStreamSubscription!.isPaused
                        ? 'Resume'
                        : 'Pause',
                    backgroundColor: _determineButtonColor(),
                  ),
                  sizedBox,
                  FloatingActionButton(
                    heroTag: "btn2",
                    child: const Icon(Icons.my_location),
                    onPressed: _getCurrentPosition,
                  ),
                  sizedBox,
                  FloatingActionButton(
                    heroTag: "btn1",
                    child: const Icon(Icons.map),
                    onPressed:(){
                       Navigator.of(context).push(MaterialPageRoute(builder: (context)=>MapPage(latlen:latLen,)));
                    },
                  ),
                ],
              ),
            ),
          )
        ]);
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePositionList(
      _PositionItemType.position,
      position.toString(),
    );
  }


  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _updatePositionList(
        _PositionItemType.log,
        _kLocationServicesDisabledMessage,
      );

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _updatePositionList(
          _PositionItemType.log,
          _kPermissionDeniedMessage,
        );

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _updatePositionList(
        _PositionItemType.log,
        _kPermissionDeniedForeverMessage,
      );

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _updatePositionList(
      _PositionItemType.log,
      _kPermissionGrantedMessage,
    );
    return true;
  }

  List stringtoposition(String postion){
    List pos1 = postion.split(',');
      pos1[0] = pos1[0].substring(10);
    pos1[1] = pos1[1].substring(12);
    return pos1;

  }





  
  
  void _updatePositionList(_PositionItemType type, String displayValue) {
    if (type==_PositionItemType.position){
      List tempcoordi = stringtoposition(displayValue);
      latLen.add(LatLng(double.parse(tempcoordi[0]), double.parse(tempcoordi[1])));
      if (startposition==false){
        startposition = true;
      }else{
        List prevposlist = stringtoposition(previousposi);
        List currentlist = stringtoposition(displayValue);
        print(prevposlist);
        print(currentlist);
        

        double tempdis = Geolocator.distanceBetween(double.parse(prevposlist[0]), double.parse(prevposlist[1]), double.parse(currentlist[0]),double.parse(currentlist[1]));
        distance = distance + tempdis;
        
      }
      previousposi = displayValue;

    }
    _positionItems.add(_PositionItem(type, displayValue));
    setState(() {});
       
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription!.isPaused);

  Color _determineButtonColor() {
    return _isListening() ? Colors.green : Colors.red;
  }

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
            _serviceStatusStreamSubscription?.cancel();
            _serviceStatusStreamSubscription = null;
          }).listen((serviceStatus) {
            String serviceStatusValue;
            if (serviceStatus == ServiceStatus.enabled) {
              if (positionStreamStarted) {
                _toggleListening();
              }
              serviceStatusValue = 'enabled';
            } else {
              if (_positionStreamSubscription != null) {
                setState(() {
                  _positionStreamSubscription?.cancel();
                  _positionStreamSubscription = null;
                  _updatePositionList(
                      _PositionItemType.log, 'Position Stream has been canceled');
                });
              }
              serviceStatusValue = 'disabled';
            }
            _updatePositionList(
              _PositionItemType.log,
              'Location service has been $serviceStatusValue',
            );
          });
    }
  }

  void _toggleListening() {
    final LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.best,
  distanceFilter: 0,
);
    if (_positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream(locationSettings: locationSettings);
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      }).listen((position) => _updatePositionList(
        _PositionItemType.position,
        position.toString(),
      ));
      _positionStreamSubscription?.pause();
    }

    setState(() {
      if (_positionStreamSubscription == null) {
        return;
      }

      String statusDisplayValue;
      if (_positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
        statusDisplayValue = 'resumed';
      } else {
        _positionStreamSubscription!.pause();
        statusDisplayValue = 'paused';
      }

      _updatePositionList(
        _PositionItemType.log,
        'Listening for position updates $statusDisplayValue',
      );
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }

    super.dispose();
  }

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      _updatePositionList(
        _PositionItemType.position,
        position.toString(),
      );
    } else {
      _updatePositionList(
        _PositionItemType.log,
        'No last known position available',
      );
    }
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  void _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: "TemporaryPreciseAccuracy",
    );
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    _updatePositionList(
      _PositionItemType.log,
      '$locationAccuracyStatusValue location accuracy granted.',
    );
  }

  void _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Application Settings.';
    } else {
      displayValue = 'Error opening Application Settings.';
    }

    _updatePositionList(
      _PositionItemType.log,
      displayValue,
    );
  }

  void _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Location Settings';
    } else {
      displayValue = 'Error opening Location Settings';
    }

    _updatePositionList(
      _PositionItemType.log,
      displayValue,
    );
  }
}

enum _PositionItemType {
  log,
  position,
}


class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}








// class MapPage extends StatefulWidget {
//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   GoogleMapController? myMapController;
//   final Set<Marker> _markers = new Set();
//   static const LatLng _mainLocation = const LatLng(25.69893, 32.6421);
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         home: Scaffold(
//             appBar: AppBar(
//               title: Text('Maps With Marker'),
//               backgroundColor: Colors.blue[900],
//             ),
//             body: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Expanded(
//                   child: GoogleMap(
//                     initialCameraPosition: CameraPosition(
//                       target: _mainLocation,
//                       zoom: 10.0,
//                     ),
//                     markers: this.myMarker(),
//                     mapType: MapType.normal,
//                     onMapCreated: (controller) {
//                       setState(() {
//                         myMapController = controller;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             )));
//   }

//   Set<Marker> myMarker() {
//     setState(() {
//       _markers.add(Marker(
//         // This marker id can be anything that uniquely identifies each marker.
//         markerId: MarkerId(_mainLocation.toString()),
//         position: _mainLocation,
//         infoWindow: InfoWindow(
//           title: 'Historical City',
//           snippet: '5 Star Rating',
//         ),
//         icon: BitmapDescriptor.defaultMarker,
//       ));
//     });

//     return _markers;
//   }
// }