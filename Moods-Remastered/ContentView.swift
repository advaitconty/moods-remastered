import SwiftUI
import UIKit

struct ContentView: View {
    @State var albumImageCover: String = ""
    @State var playlists: [String: [String]] = [:]
    @State var currentSong: String? = nil
    @State var availableSongs: [String] = []
    @State var searchText: String = ""
    @State var errorMessage: IdentifiableError? = nil
    @State var artist: String = ""
    @State var song: String = ""
    @State var moodSelectedSong: String = ""
    @State var reload: Bool = false
    @State var mood: String = ""
    @State var playing: Bool = true
    @State var showMoods: Bool = false
    @State var showReasonPopup: Bool = false
    @State var reason: String = ""
    @Environment(\.dismiss) var dismiss
    @Binding var apiBaseURL: String
    @Binding var apiKey: String
    @Binding var showIt: Bool
    @State var reason_played = ""
    
    private let customFont = Font.custom("Playfair Display", size: 36)
    
    func AIMoodsView() -> some View {
        Form {
            Text("What are you in the mood for:")
                .font(.custom("Raleway", size: 16))
            TextField("A happy song from JVKE", text: $mood)
                .font(.custom("Raleway", size: 16))
            Button {
                if mood == "" {
                    errorMessage = IdentifiableError(message: "Text is blank")
                } else {
                    Task {
                        playAIMoods(mood: mood)
                        errorMessage = IdentifiableError(message: reason_played)
                        dismiss()
                    }
                }
            } label: {
                Text("Submit!")
            }
            
            if let error = errorMessage {
                Text(error.message)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .background {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .presentationDetents([.medium])
    }
    
    var body: some View {
        ZStack {
            VStack {
                NavigationStack {
                    List {
                        if playing == true && currentSong != nil {
                            if reload == false {
                                Section(header: CustomText(text: "Now Playing", size: 14, font: "Raleway")) {
                                    VStack {
                                        HStack {
                                            AsyncImage(url: URL(string: albumImageCover)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxWidth: 100, maxHeight: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 7.0))
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .onAppear {
                                                Task {
                                                    do {
                                                        if let artworkURL = try await getArtworkURL(for: currentSong!) {
                                                            albumImageCover = artworkURL
                                                        }
                                                    } catch {
                                                        errorMessage = IdentifiableError(message: "Failed to load image: \(error)")
                                                    }
                                                }
                                                
                                                let components = currentSong!.split(separator: " - ", maxSplits: 1)
                                                
                                                artist = components.count > 0 ? String(components[0]) : ""
                                                song = components.count > 1 ? String(components[1]) : ""
                                            }
                                            
                                            VStack {
                                                HStack {
                                                    Text(artist)
                                                        .font(.custom("Raleway", size: 16))
                                                    
                                                    Spacer()
                                                }
                                                
                                                HStack {
                                                    Text(song)
                                                        .font(.custom("Raleway", size: 20))
                                                    
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("_Loading..._")
                                    .font(.custom("Raleway", size: 16))
                                    .onAppear {
                                        reload = false
                                    }
                            }
                        } else if playing == false {
                            Text("_No song is currently playing_")
                                .font(.custom("Raleway", size: 16))
                        }
                        
                        Section("Songs") {
                            ForEach(filteredSongs, id: \..self) { song in
                                Button(action: {
                                    reload = true
                                    playing = true
                                    playSong(song: song)
                                }) {
                                    Text(song)
                                        .font(.custom("Raleway", size: 16))
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showMoods) {
                        AIMoodsView()
                    }
                    .searchable(text: $searchText)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if playing {
                            ToolbarItem(placement: .bottomBar) {
                                Button {
                                    playing = false
                                    sendPlaybackCommand(endpoint: "/pause")
                                } label: {
                                    Image(systemName: "pause")
                                }
                                .padding()
                                .foregroundColor(.white)
                            }
                        } else {
                            ToolbarItem(placement: .bottomBar) {
                                Button {
                                    playing = true
                                    sendPlaybackCommand(endpoint: "/resume")
                                } label: {
                                    Image(systemName: "play")
                                }
                                .padding()
                                .foregroundColor(.white)
                                
                            }
                        }
                        
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                playing = false
                                sendPlaybackCommand(endpoint: "/stop")
                                albumImageCover = ""
                                currentSong = nil
                            } label: {
                                Image(systemName: "stop")
                            }
                            .padding()
                            .foregroundColor(.white)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("_Moods_")
                                .font(customFont)
                                .foregroundColor(.white)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showMoods = true
                            } label: {
                                Image(systemName: "heart.text.square.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                reload = true
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .background {
                        Image("Background")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                    .scrollContentBackground(.hidden)
                    
                }
                .onAppear {
                    setupNavigationBarAppearance()
                    loadPlaylists()
                    loadAvailableSongs()
                    loadCurrentSong()
                }
                .alert(item: $errorMessage) { error in
                    Alert(title: Text("Alert"), message: Text(error.message), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    var filteredSongs: [String] {
        if searchText.isEmpty {
            return availableSongs
        } else {
            return availableSongs.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Playfair Display", size: 24)!
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Playfair Display", size: 34)!
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Ensure toolbar has the same blur effect
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithTransparentBackground()
        toolbarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark) // Subtle blur in black
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().compactAppearance = toolbarAppearance
    }
    
    
    func loadPlaylists() {
        guard let url = URL(string: "\(apiBaseURL)/playlists") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode([String: [String]].self, from: data)
                DispatchQueue.main.async {
                    playlists = decoded
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: "Failed to decode playlists")
                }
            }
        }.resume()
    }
    
    func loadAvailableSongs() {
        guard let url = URL(string: "\(apiBaseURL)/available") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    availableSongs = decoded
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: "Failed to decode available songs")
                }
            }
        }.resume()
    }
    
    func playSong(song: String) {
        Task {
            do {
                sendPlaybackCommand(endpoint: "/stop")
            } catch {
                errorMessage = IdentifiableError(message: "Failed to stop song first")
                return
            }
        }
        guard let url = URL(string: "\(apiBaseURL)/play") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["key": apiKey, "song": song]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = IdentifiableError(message: "Failed to encode song data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            loadCurrentSong()
        }.resume()
        
        currentSong = song
    }
    
    func playPlaylist(playlist: String) {
        guard let url = URL(string: "\(apiBaseURL)/play") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["key": apiKey, "playlist": playlist]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = IdentifiableError(message: "Failed to encode song data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            loadCurrentSong()
        }.resume()
    }
    
    func playAIMoods(mood: String) {
        guard let url = URL(string: "\(apiBaseURL)/play-with-mood") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["key": apiKey, "mood": mood]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = IdentifiableError(message: "Failed to encode mood data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error.localizedDescription)
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode([String: String].self, from: data)
                
                guard let chosenSong = decodedResponse["playing"], let reason = decodedResponse["reason"] else {
                    print(decodedResponse)
                    
                    DispatchQueue.main.async {
                        errorMessage = IdentifiableError(message: "Invalid response data")
                    }
                    return
                }
                loadCurrentSong()
                print(decodedResponse["reason"])
                errorMessage = IdentifiableError(message: decodedResponse["reason"]!)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: "Failed to decode mood response")
                }
            }
        }.resume()
        
        reload = true
    }
    
    func showAlert(reason: String) {
        let alert = UIAlertController(title: "Song Chosen", message: "The song was chosen because: \(reason)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    
    
    func loadCurrentSong() {
        guard let url = URL(string: "\(apiBaseURL)/current") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode([String: String].self, from: data)
                DispatchQueue.main.async {
                    currentSong = decoded["song_playing"]
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: "Failed to decode current song")
                }
            }
        }.resume()
    }
    
    func sendPlaybackCommand(endpoint: String) {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = IdentifiableError(message: error.localizedDescription)
                }
                return
            }
            
            loadCurrentSong()
        }.resume()
    }
    
    func getArtworkURL(for songName: String) async throws -> String? {
        let encodedTerm = songName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? songName
        print(encodedTerm)
        let urlString = "https://itunes.apple.com/search?term=\(encodedTerm)&entity=song"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let results: [Result]
            
            struct Result: Codable {
                let artworkUrl100: String
            }
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        
        print(response)
        
        print(response.results.first?.artworkUrl100)
        
        guard let firstArtwork = response.results.first?.artworkUrl100 else {
            return nil
        }
        
        return firstArtwork.replacingOccurrences(of: "100x100", with: "600x600")
    }
}
