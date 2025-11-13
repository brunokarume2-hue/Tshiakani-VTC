//
//  LoaderView.swift
//  Tshiakani VTC
//
//  Loader réutilisable pour les modals
//

import SwiftUI

struct LoaderView: View {
    var message: String? = nil
    
    var body: some View {
        TshiakaniFullScreenLoader(message: message)
    }
}

#Preview {
    LoaderView(message: "Chargement...")
}

