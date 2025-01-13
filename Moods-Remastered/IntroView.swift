//
//  IntroView.swift
//  Moods-Remastered
//
//  Created by Milind Contractor on 12/1/25.
//

import SwiftUI
import Forever

struct IntroView: View {
    @Forever("userData") var userData = StorageData()
    @AppStorage("firstLaunch") var firstLaunch = true
    @State var showIt = false
    
    var body: some View {
        VStack {
            List {
                if firstLaunch {
                    VStack {
                        HStack {
                            Text("_Moods_")
                                .font(.custom("Playfair Display", size: 36))
                            Spacer()
                        }
                        HStack {
                            Text("Please start by configuring your Moods server URL and key")
                                .font(.custom("Raleway", size: 16))
                            Spacer()
                        }
                    }
                } else {
                    HStack {
                        Text("Settings")
                            .font(.custom("Playfair Display", size: 36))
                        Spacer()
                    }
                }
                HStack {
                    Text("URL:")
                        .font(.custom("Raleway", size: 16))
                    Divider()
                    TextField("http://moods.advaitconty.com", text: $userData.url)
                        .font(.custom("Raleway", size: 16))
                        .keyboardType(.URL)
                }
                HStack {
                    Text("Key:")
                        .font(.custom("Raleway", size: 16))
                    Divider()
                    SecureField("some password", text: $userData.key)
                        .font(.custom("Raleway", size: 16))
                }
                Button {
                    showIt = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        if firstLaunch {
                            Text("Finish setup!")
                                .font(.custom("Raleway", size: 16))
                        } else {
                            Text("Apply changes")
                                .font(.custom("Raleway", size: 16))
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showIt) {
            ContentView(apiBaseURL: $userData.url, apiKey: $userData.key, showIt: $showIt)
        }
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}
