import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct ContentView: View {
    @StateObject private var viewModel = AppListViewModel()
    @State private var searchText = ""
    @State private var currentPageIndex: Int = 0
    @State private var draggedApp: AppInfo?
    @State private var dragOffset = CGSize.zero
    @State private var showingFolderNameAlert = false
    @State private var folderName = ""
    @State private var appsToCreateFolder: [AppInfo] = []
    @State private var hoveredApp: AppInfo?
    @State private var highlightedApp: AppInfo?
    @FocusState private var isSearchFocused: Bool
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)

    var body: some View {
        ZStack {
            backgroundView
            
            if viewModel.showingFolderView {
                folderView
            } else {
                mainLaunchpadView
            }
        }
        .ignoresSafeArea()
        .onAppear { 
            viewModel.fetchInstalledApps()
            searchText = ""
            highlightedApp = nil
        }
        .onChange(of: searchText) { _, newQuery in
            viewModel.filterApps(with: newQuery)
            updateHighlightedApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClearSearch"))) { _ in
            searchText = ""
            highlightedApp = nil
        }
        .onKeyPress(.return) {
            if isSearchFocused, let highlightedApp = highlightedApp {
                handleAppTap(highlightedApp)
                return .handled
            }
            return .ignored
        }
        .alert("Create Folder", isPresented: $showingFolderNameAlert) {
            TextField("Folder Name", text: $folderName)
            Button("Create") {
                if !folderName.isEmpty {
                    viewModel.createFolder(from: appsToCreateFolder, named: folderName)
                    folderName = ""
                    appsToCreateFolder = []
                }
            }
            Button("Cancel", role: .cancel) {
                folderName = ""
                appsToCreateFolder = []
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.1))
                .background(.ultraThinMaterial, in: Rectangle())
                .ignoresSafeArea()
        }
    }
    
    private var mainLaunchpadView: some View {
        VStack(spacing: 30) {
            searchBar
            
            appGridView
            
            pageIndicators
        }
        .padding(.top, 40)
        .padding(.bottom, 120)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
        .frame(width: 300)
    }
    
    private var appGridView: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.appPages.enumerated()), id: \.offset) { pageIndex, pageOfApps in
                        LazyVGrid(columns: columns, spacing: 25) {
                            ForEach(Array(pageOfApps.enumerated()), id: \.element.id) { appIndex, app in
                                appIcon(app, pageIndex: pageIndex, appIndex: appIndex)
                            }
                        }
                        .padding(.horizontal, 80)
                        .padding(.vertical, 30)
                        .frame(width: geometry.size.width, alignment: .center)
                    }
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).origin)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let newIndex = Int(round(-value.x / geometry.size.width))
                    if newIndex >= 0 && newIndex < viewModel.appPages.count {
                         self.currentPageIndex = newIndex
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .coordinateSpace(name: "scroll")
        }
    }
    
    private func appIcon(_ app: AppInfo, pageIndex: Int, appIndex: Int) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if highlightedApp?.id == app.id {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 88, height: 88)
                        .animation(.easeInOut(duration: 0.3), value: highlightedApp?.id)
                }
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .frame(width: 85, height: 85)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scaleEffect(hoveredApp?.id == app.id ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredApp?.id == app.id)
                
                if app.isFolder {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                                .offset(x: -8, y: -8)
                        }
                    }
                }
            }
            
            Text(app.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .lineLimit(1)
                .frame(width: 85)
                .animation(.easeInOut(duration: 0.3), value: highlightedApp?.id)
        }
        .scaleEffect(draggedApp?.id == app.id ? 0.9 : 1.0)
        .opacity(draggedApp?.id == app.id ? 0.7 : 1.0)
        .offset(draggedApp?.id == app.id ? dragOffset : .zero)
        .onTapGesture {
            handleAppTap(app)
        }
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredApp = isHovering ? app : nil
            }
        }
    }
    
    private func appDragPreview(_ app: AppInfo) -> some View {
        VStack(spacing: 4) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)
            
            Text(app.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
        .opacity(0.8)
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.appPages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPageIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPageIndex)
            }
        }
    }
    
    private var folderView: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Done") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.closeFolderView()
                    }
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Text(viewModel.currentFolderName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("") { }
                    .opacity(0)
            }
            .padding(.horizontal, 40)
            .padding(.top, 60)
            
            LazyVGrid(columns: columns, spacing: 25) {
                ForEach(viewModel.selectedFolderApps) { app in
                    VStack(spacing: 8) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Text(app.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        NSWorkspace.shared.open(app.url)
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.toggleLaunchpad()
                        }
                    }
                }
            }
            .padding(.horizontal, 80)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    private func handleAppTap(_ app: AppInfo) {
        if app.isFolder {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.openFolder(app)
            }
        } else {
            NSWorkspace.shared.open(app.url)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.toggleLaunchpad()
                } else if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.toggleLaunchpad()
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("CloseLaunchBoard"), object: nil)
                }
            }
        }
    }
    
    private func handleAppDrop(droppedApps: [AppInfo], targetApp: AppInfo, pageIndex: Int, appIndex: Int) -> Bool {
        guard let droppedApp = droppedApps.first else { return false }
        
        if droppedApp.id == targetApp.id { return false }
        
        if !targetApp.isFolder {
            print("Creating folder with \(droppedApp.name) and \(targetApp.name)")
            appsToCreateFolder = [droppedApp, targetApp]
            showingFolderNameAlert = true
            return true
        }
        
        if targetApp.isFolder {
            print("Adding \(droppedApp.name) to folder \(targetApp.name)")
            viewModel.addAppToFolder(app: droppedApp, folder: targetApp)
            return true
        }
        
        return false
    }
    
    private func updateHighlightedApp() {
        if searchText.isEmpty {
            highlightedApp = nil
            return
        }
        
        for page in viewModel.appPages {
            if let firstMatch = page.first(where: { $0.name.lowercased().contains(searchText.lowercased()) }) {
                highlightedApp = firstMatch
                return
            }
        }
        
        highlightedApp = nil
    }
}
