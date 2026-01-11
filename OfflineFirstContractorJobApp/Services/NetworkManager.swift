//
//  NetworkManager.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import Foundation
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = false
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("NetworkStatusChanged"), object: nil)
            }
        }
        monitor.start(queue: queue)
        isConnected = monitor.currentPath.status == .satisfied
    }
}

