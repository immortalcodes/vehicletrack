import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
final List<LatLng>? latlen;
const MapPage({Key? key,this.latlen}) : super(key: key);

@override
_MapPageState createState() => _MapPageState(latLen: this.latlen);
}

class _MapPageState extends State<MapPage> {
List<LatLng>?latLen ;
_MapPageState({this.latLen});
// created controller to display Google Maps
Completer<GoogleMapController> _controller = Completer();
//on below line we have set the camera position
static final CameraPosition _kGoogle = const CameraPosition(
	target: LatLng(21.162823, 81.658913),
	zoom: 14,
);

final Set<Marker> _markers = {};
final Set<Polyline> _polyline = {};

// list of locations to display polylines
@override
void initState() {


  // _polyline.add(
    
	// 	 Polyline(
  //       polylineId: const PolylineId('direction'),
  //       color: Colors.blue,
  //       points: [LatLng(21.1609418, 81.6588971),LatLng(21.1609378, 81.6588985)],
  //       width: 5,
  //       startCap: Cap.roundCap,
  //       endCap: Cap.roundCap,
  //       jointType: JointType.round,
  //       geodesic: true,
  //     )
	// );



	// TODO: implement initState
	super.initState();
  print("MJ ${latLen}");
  int lenCordinates = latLen!.length;
	// declared for loop for various locations
	for(int i=0; i<lenCordinates; i++){
	print("loop running");
  _markers.add(
		// added markers
		Marker(
			markerId: MarkerId(i.toString()),
		position: latLen![i],
		infoWindow: InfoWindow(
			title: 'HOTEL',
			snippet: '5 Star Hotel',
		),
		icon: BitmapDescriptor.defaultMarker,
		)
	);
	setState(() {

	});
  if(i!=0 && i!=lenCordinates){
	_polyline.add(
    
		 Polyline(
        polylineId: const PolylineId('direction'),
        color: Colors.blue,
        points: [latLen![i-1],latLen![i]],
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        geodesic: true,
      )
	);}
	}
}

@override
Widget build(BuildContext context) {
  print(_polyline);
  print("upar hai polyline");
	return Scaffold(
	appBar: AppBar(
		backgroundColor: Color(0xFF0F9D58),
		// title of app
		title: Text("Displaying Route"),
	),
	
  body: Container(
		child: SafeArea(
		child: GoogleMap(
			//given camera position
			initialCameraPosition: _kGoogle,
			// on below line we have given map type
			mapType: MapType.satellite,
			// specified set of markers below
			// on below line we have enabled location
			myLocationEnabled: true,
			myLocationButtonEnabled: true,
			// on below line we have enabled compass location
			compassEnabled: true,
			// on below line we have added polylines
			polylines: _polyline,
			// displayed google map
			onMapCreated: (GoogleMapController controller){
				_controller.complete(controller);
        print("map Created");
			},
		),
		),
	),
);
}
}
