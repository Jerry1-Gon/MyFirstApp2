//
//  ContentView.swift
//  FirstSwiftUI
//
//  Created by Gonzalez, Jerardo on 3/23/26.
//

import SwiftUI

struct ContentView: View {
    @State private var name: String = ""
    @State private var showGreeting: Bool = false
    @State private var fontSize: Double = 10 // slider needs Double

    
    
    
    
    var body: some View {
        VStack(spacing: 16) {
            Image("welcome")
              .resizable()
              .frame(width: 200, height: 200)
          
          TextField("Enter your name", text: $name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            /*
            
            Button("Show Greeting") {
                    // when pressed, reveal the greeting
                    showGreeting = true
                    }
                .padding(.vertical, 8)
             */
            
            Toggle("Show Greeting (switch)", isOn: $showGreeting)
            .padding(.horizontal)
            
            
            
            Text("Font Size: \(Int(fontSize))")
              Slider(value: $fontSize, in: 10...50, step: 1)
                .padding(.horizontal)

            
            
            
            
            // greeting label appears when showGreeting is true
            if showGreeting {
                Text("Hello, \(name.isEmpty ? "World" : name)!")
                .font(.system(size: CGFloat(fontSize)))
                        .fontWeight(.bold)
                
                .padding()
                .border(Color.gray, width: 4)
            }

            
            
            
            
           Spacer()
        }
        .padding()
        
        
        
        
        
    } // closing body
}  //closing ContentView

#Preview {
    ContentView()
}
