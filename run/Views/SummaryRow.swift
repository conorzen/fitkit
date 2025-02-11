//
//  SummaryRow.swift
//  run
//
//  Created by Conor Reid Admin on 11/02/2025.
//

import SwiftUI

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
