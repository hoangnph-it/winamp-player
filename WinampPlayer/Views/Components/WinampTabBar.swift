import SwiftUI

/// Minimal tab bar for switching between Playlist / Library / Search
struct WinampTabBar: View {
    @Binding var selectedTab: Int
    private let tabs = ["PLAYLIST", "LIBRARY", "SEARCH"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button { selectedTab = i } label: {
                    Text(tabs[i])
                        .font(WinampTheme.btnFont)
                        .foregroundColor(selectedTab == i ? WinampTheme.btnActive : WinampTheme.btnText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(selectedTab == i ? WinampTheme.frameDark : WinampTheme.btnFace)
                        .overlay(BevelBorder(pressed: selectedTab == i))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
