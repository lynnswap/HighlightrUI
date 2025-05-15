//
//  HighlightrStore.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//
import Highlightr
import SwiftUI

@MainActor
@Observable class HighlightrStore{
    static let shared = HighlightrStore()
    let availableThemes:[String]
    init(){
        self.availableThemes = Highlightr()?.availableThemes().sorted() ?? []
    }
}
