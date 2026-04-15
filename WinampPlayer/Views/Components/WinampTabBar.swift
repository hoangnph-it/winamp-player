import SwiftUI

/// Winamp-style tab bar for switching between Playlist, Library, Search
struct WinampTabBar: View {
    @Binding var selectedTab: Int

    private let tabs = ["PLAYLIST", "LIBRARY", "SEARCH"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    Text(tabs[index])
                        .font(WinampTheme.buttonFont)
                        .foregroundColor(selectedTab == index ? WinampTheme.lcdGreen : WinampTheme.buttonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selectedTab == index
                                ? WinampTheme.panelBackground
                                : WinampTheme.buttonFace
                        )
                        .overlay(
                            VStack(spacing: 0) {
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(WinampTheme.lcdGreen)
                                        .frame(height: 2)
                                }
                                Spacer()
                            }
                        )
                }
                .buttonStyle(.plain)

                if index < tabs.count - 1 {
                    Rectangle()
                        .fill(WinampTheme.buttonShadow)
                        .frame(width: 1)
                }
            }
        }
        .background(WinampTheme.buttonFace)
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(WinampTheme.displayBorder).frame(height: 1)
            }
        )
    }
}
