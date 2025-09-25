import SwiftUI

struct SettingsView: View {
    @State private var showingGeneralSettings = false
    @State private var showingNotifications = false
    @State private var showingAudioSettings = false
    @State private var showingProfile = false
    @State private var showingPrivacy = false
    @State private var showingHelp = false
    @State private var showingContact = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("App Settings")) {
                    Button(action: {
                        showingGeneralSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                            Text("General Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingNotifications = true
                    }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.orange)
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingAudioSettings = true
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.green)
                            Text("Audio Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Account")) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.purple)
                            Text("Profile")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingPrivacy = true
                    }) {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.red)
                            Text("Privacy & Security")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Support")) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingContact = true
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                            Text("Contact Us")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                            Text("About")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $showingGeneralSettings) {
            GeneralSettingsView()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showingAudioSettings) {
            AudioSettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingContact) {
            ContactView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// Placeholder views for each settings section
struct GeneralSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("General Settings")
                    .font(.title2)
                    .padding()
                Text("Configure general app preferences")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("General Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Notifications")
                    .font(.title2)
                    .padding()
                Text("Manage notification preferences")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AudioSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Audio Settings")
                    .font(.title2)
                    .padding()
                Text("Configure audio recording and playback")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile")
                    .font(.title2)
                    .padding()
                Text("Manage your user profile")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Privacy & Security")
                    .font(.title2)
                    .padding()
                Text("Manage privacy and security settings")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Help & Support")
                    .font(.title2)
                    .padding()
                Text("Get help and support for the app")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Contact Us")
                    .font(.title2)
                    .padding()
                Text("Get in touch with our support team")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("About")
                    .font(.title2)
                    .padding()
                Text("Learn more about SpeakNativeAmerican")
                    .foregroundColor(.secondary)
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                Spacer()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
