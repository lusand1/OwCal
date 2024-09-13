//
//  NetworkAuth.swift
//  OwCal
//
//  Created by dog on 2024/7/30.
//

import Foundation

func networkAuth(id: String, pwd: String) {
    // Constants
    let plen = 13
    let baseURL = "http://172.20.170.176/ac_portal/login.php"
    
    // Generate authTag
    let timestamp = Int(Date().timeIntervalSince1970)
    let randomValue = String(format: "%03d", Int.random(in: 0...999))
    let authTag = "\(timestamp)\(randomValue)"
    
    // Initialize RC4 arrays
    var keyArray256 = [Int](repeating: 0, count: 256)
    var sboxArray256 = Array(0..<256)
    let pwdCount = pwd.count
    var encryptedPwdArray = [String](repeating: "", count: pwdCount)
    
    // Fill keyArray256 with values from authTag
    for i in 0..<256 {
        let index = authTag.index(authTag.startIndex, offsetBy: i % plen)
        keyArray256[i] = Int(authTag[index].unicodeScalars.first!.value)
    }
    
    // Initialize S-box
    var j = 0
    for i in 0..<256 {
        j = (j + sboxArray256[i] + keyArray256[i]) % 256
        sboxArray256.swapAt(i, j)
    }
    
    // Encrypt password using RC4
    var a = 0
    var b = 0
    for i in 0..<pwdCount {
        a = (a + 1) % 256
        b = (b + sboxArray256[a]) % 256
        sboxArray256.swapAt(a, b)
        let c = (sboxArray256[a] + sboxArray256[b]) % 256
        let char = pwd[pwd.index(pwd.startIndex, offsetBy: i)]
        let encryptedChar = Int(char.unicodeScalars.first!.value) ^ sboxArray256[c]
        encryptedPwdArray[i] = String(format: "%02x", encryptedChar)
    }
    
    // Create the final URL-encoded password
    let urlpwd = encryptedPwdArray.joined()
    
    // Prepare URL request
    guard let url = URL(string: baseURL) else {
        print("Error: Invalid NetAuth URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let postString = "opr=pwdLogin&userName=\(id)&pwd=\(urlpwd)&auth_tag=\(authTag)&home=1"
    request.httpBody = postString.data(using: .utf8)
    
    // Perform network request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid response")
            return
        }
        
        if httpResponse.statusCode == 200 {
            if let _ = data {
//                print("Success: \(String(data: data, encoding: .utf8) ?? "No Data")")
            }
        } else {
            print("Error: \(httpResponse.statusCode)")
        }
    }
    task.resume()
}
