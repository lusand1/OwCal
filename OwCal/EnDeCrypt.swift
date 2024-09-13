//
//  Crypto.swift
//  OwCal
//
//  Created by dog on 2024/8/14.
//

func encrypt(input: String) -> String {
    let mapping: [Character: Character] = [
        "0": "®",
        "1": "†",
        "2": "å",
        "3": "∂",
        "4": "ƒ",
        "5": "©",
        "6": "∆",
        "7": "˚",
        "8": "¬",
        "9": "∫"
    ]
    
    return String(input.map { mapping[$0] ?? $0 })
}

func decrypt(input: String) -> String {
    let reverseMapping: [Character: Character] = [
        "®": "0",
        "†": "1",
        "å": "2",
        "∂": "3",
        "ƒ": "4",
        "©": "5",
        "∆": "6",
        "˚": "7",
        "¬": "8",
        "∫": "9"
    ]
    
    return String(input.map { reverseMapping[$0] ?? $0 })
}
