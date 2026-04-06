//
//  ContentView.swift
//  TableSwiftUI
//
//  Created by Gonzalez, Jerardo on 3/25/26.
//

import SwiftUI
import MapKit

let data = [
    Item(name: "Adidas", neighborhood: "San Marcos Premium Outlets - Athletic Wear Section", desc: "A store offering a variety of sports gear and footwear for people who enjoy sports and active lifestyles.", stores: "This store sells Adidas shoes along with different types of sports gear and clothing.", address:"3939 S I-35 South Frontage Rd Suite 770" , lat: 29.8285, long: -97.9865, imageName: "rest1"),
    Item(name: "Puma", neighborhood: "San Marcos Premium Outlets - Sportswear Row", desc: "Offers different styles of shoes, especially popular among people who like trendy and sporty fashion.", stores: "This store sells Puma shoes and apparel, which are popular among many Hispanic and urban communities.", address:"3939 I-35 Suite 798.",lat: 29.8289, long: -97.9859, imageName: "rest2"),
    Item(name: "Nike", neighborhood: "San Marcos Premium Outlets - Nike Factory Area", desc: "One of the most popular brands among younger audiences, known for stylish and high-performance shoes.", stores:"This store sells Nike and Jordan shoes, along with branded clothing that matches the footwear.", address:"1905 Aldrich St.", lat:29.8279, long: -97.9872, imageName: "rest3"),
    Item(name: "JD", neighborhood: "Tanger Outlets San Marcos - Sneaker & Streetwear Section", desc: " A popular retailer known for athletic shoes and streetwear inspired by basketball culture.",stores:"This store sells sneakers inspired by famous basketball players, especially from the 1980s era.",address:"104 E. 31st St.", lat: 29.8275, long: -97.9868, imageName: "rest4"),
    Item(name: "Converse", neighborhood: "San Marcos Premium Outlets - Casual Footwear Zone", desc: "Classic shoes that are popular among skaters and people who enjoy casual style.",stores:"This store is great for people who like skateboarding or biking, offering shoes with good grip and comfort.",address:"4222 Duval St", lat: 29.8292, long: -97.9854, imageName: "rest5")
]


    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let neighborhood: String
        let desc: String
        let stores: String
        let address: String
        let lat: Double
        let long: Double
        let imageName: String
    }



struct ContentView: View {
// initialize variables for Map in List View abd set zoom and centering location
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 29.8285, longitude: -97.9865), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    let stores = ["All"] + Array(Set(data.map { $0.stores })).sorted()
          @State private var selectedCategory = "All"
    var filteredData: [Item] {
               if selectedCategory == "All" {
                   return data
               } else {
                   return data.filter { $0.stores == selectedCategory }
               }
           } // end filteredData
        
    
    
var body: some View {
    NavigationView {
    VStack {
        Picker("Category", selection: $selectedCategory) {
                  ForEach(stores, id: \.self) { category in
                      Text(category).tag(category)
                  }
              } // end Picker
              .pickerStyle(.menu)
              .padding()
              .background(Color.white.opacity(0.8))
                                  .cornerRadius(12)
        
      
        List(filteredData, id:\.name) { item in
            NavigationLink(destination: DetailView(item: item)) {
                HStack {
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.stores)
                            .font(.subheadline)
                        Text(item.neighborhood)
                            .font(.subheadline)
                    } // end internal VStack
                } // end HStack
            } // end NavigationLink
        } // end List
    
// Map code inserted after list
Map(coordinateRegion: $region, annotationItems: data) { item in
MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.lat, longitude: item.long)) {
Image(systemName: "mappin.circle.fill")
    .foregroundColor(.red)
    .font(.title)
    .overlay(
Text(item.name)
       .font(.subheadline)
       .foregroundColor(.black)
       .fixedSize(horizontal: true, vertical: false)
       .offset(y: 25)
)
}
} // end Map
.frame(height: 300)
.padding(.bottom, -30)
            
            
        } // end VStack
        .listStyle(PlainListStyle())
             .navigationTitle("San Marcos Mall")
         } // end NavigationView
    } // end body
}


struct DetailView: View {
// initialize variables for Map in Detail View abd set zoom and centering on specific item
@State private var region: MKCoordinateRegion
         
init(item: Item) {
self.item = item
_region = State(initialValue: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: item.lat, longitude: item.long), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
}
        
let item: Item
               
var body: some View {
VStack {
   Image(item.imageName)
       .resizable()
       .aspectRatio(contentMode: .fit)
       .frame(maxWidth: 200)
   Text("Neighborhood: \(item.neighborhood)")
       .font(.subheadline)
   Text((item.address))
       .font(.subheadline)
       .frame(maxWidth: .infinity, alignment: .leading)
       .padding()
   Text("Description: \(item.desc)")
       .font(.subheadline)
       .padding(10)
               
//Map code in Detail View
Map(coordinateRegion: $region, annotationItems: [item]) { item in
    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.lat, longitude: item.long)) {
    Image(systemName: "mappin.circle.fill")
      .foregroundColor(.red)
      .font(.title)
      .overlay(
    Text(item.name)
      .font(.subheadline)
      .foregroundColor(.black)
      .fixedSize(horizontal: true, vertical: false)
      .offset(y: 25)
    )
    }
} // end Map
    .frame(height: 300)
    .padding(.bottom, -60)
    Spacer()
           
    } // end VStack
    .navigationTitle(item.name)
   
        } // end body
     } // end DetailView
   

#Preview {
    ContentView()
}
           
                    
    
