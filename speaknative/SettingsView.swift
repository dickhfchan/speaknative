import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("App Settings")) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("General Settings")
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.orange)
                        Text("Notifications")
                    }
                    
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.green)
                        Text("Audio Settings")
                    }
                }
                
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.purple)
                        Text("Profile")
                    }
                    
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.red)
                        Text("Privacy & Security")
                    }
                }
                
                Section(header: Text("Support")) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("Help & Support")
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.green)
                        Text("Contact Us")
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("About")
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    SettingsView()
}
