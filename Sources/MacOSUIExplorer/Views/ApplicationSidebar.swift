// ABOUTME: This file contains the sidebar view for selecting applications.
// ABOUTME: It displays a list of running applications and allows selecting one to explore.

import SwiftUI
import MacOSUICLILib

/// Sidebar view for selecting applications
struct ApplicationSidebar: View {
    @EnvironmentObject var viewModel: ApplicationViewModel
    @State private var searchText = ""
    
    var filteredApplications: [Application] {
        if searchText.isEmpty {
            return viewModel.applications
        } else {
            return viewModel.applications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedApplication.map { ApplicationWrapper($0) } },
            set: { if let wrapper = $0 { viewModel.selectApplication(wrapper.application) } }
        )) {
            Section("Quick Actions") {
                Button(action: {
                    viewModel.selectFocusedApplication()
                }) {
                    Label("Focus on Active Application", systemImage: "target")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
            }
            
            Section("Recent Applications") {
                if viewModel.recentApplications.isEmpty {
                    Text("No recent applications")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.recentApplications, id: \.pid) { app in
                        let wrapper = ApplicationWrapper(app)
                        ApplicationRow(application: app)
                            .tag(wrapper)
                    }
                }
            }
            
            Section("Running Applications") {
                if filteredApplications.isEmpty {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("No applications found")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(filteredApplications, id: \.pid) { app in
                        let wrapper = ApplicationWrapper(app)
                        ApplicationRow(application: app)
                            .tag(wrapper)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Applications")
        .refreshable {
            viewModel.refreshApplications()
        }
    }
}

/// Row view for displaying an application
struct ApplicationRow: View {
    let application: Application
    
    var body: some View {
        HStack(spacing: 12) {
            // If we had app icons, we would display them here
            Image(systemName: "app.square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(application.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text("PID: \(application.pid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
struct ApplicationSidebar_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationSidebar()
            .environmentObject(ApplicationViewModel())
            .frame(width: 300, height: 400)
    }
}
#endif