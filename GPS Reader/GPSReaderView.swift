//
//  GPSReaderView.swift
//  GPS Reader
//
//  Created by Ernesto Fernandez on 4/4/24.
//

import SwiftUI

struct GPSReaderView: View {

    @StateObject private var viewModel: GPSReaderViewModel

    // MARK: - Initialization

    init() {
        _viewModel = .init(wrappedValue: .init())
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 32.0) {
            permissionsView
            VStack {
                noSignalView
                signalBarsView
            }
        }
        .padding(32.0)
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - Subviews

    private var permissionsView: some View {
        Group {
            if viewModel.isLocationPermissionEnabled {
                EmptyView()
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Necesitas aceptar los permisos de ubicación")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var noSignalView: some View {
        Group {
            if viewModel.signalStrength == .none {
                HStack {
                    Image(systemName: "location.slash")
                    Text("Sin señal GPS")
                    Spacer()
                }
            } else {
                EmptyView()
            }
        }
    }

    private var signalBarsView: some View {
        HStack {
            Text("Calidad de la señal:")
            HStack {
                ForEach((0..<viewModel.signalStrength.bars), id: \.self) { _ in
                    Image(systemName: "circle.fill")
                }
                ForEach((viewModel.signalStrength.bars..<SignalStrength.full.bars), id: \.self) { _ in
                    Image(systemName: "circle")
                }
            }
            Spacer()
        }
    }

}

#Preview {
    GPSReaderView()
}
