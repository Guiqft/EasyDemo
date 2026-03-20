//
//  WindowSelectionViewModel.swift
//  EasyDemo
//
//  Created by Daniel Oquelis on 28.10.25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for window selection screen
@MainActor
class WindowSelectionViewModel: ObservableObject {
    @Published var selectedWindow: WindowInfo?
    @Published var isRefreshing = false

    let windowCapture = WindowCapture()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Re-check permissions when the app becomes active (e.g. after returning from System Settings)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    let hadPermission = self.windowCapture.hasScreenRecordingPermission
                    await self.windowCapture.checkScreenRecordingPermission()
                    if !hadPermission && self.windowCapture.hasScreenRecordingPermission {
                        await self.refreshWindows()
                    }
                }
            }
            .store(in: &cancellables)

        Task {
            await windowCapture.checkScreenRecordingPermission()
            if windowCapture.hasScreenRecordingPermission {
                await refreshWindows()
            }
        }
    }

    func refreshWindows() async {
        isRefreshing = true
        await windowCapture.enumerateWindows()
        isRefreshing = false
    }

    func requestPermissionAndLoadSources() async {
        // Open System Settings directly instead of triggering the system dialog,
        // which has a "Quit & Reopen" button that doesn't work with modal sheets.
        PermissionManager.shared.openSystemSettings(for: .screenRecording)
    }

    func selectWindow(_ window: WindowInfo) {
        self.selectedWindow = window
    }
}
