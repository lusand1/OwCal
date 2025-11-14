//
//  MealEat.swift
//  OwCal
//
//  Created by dog on 2025/11/11.
//

import Foundation

func parseValue(from html: String, selector: String) throws -> String? {
    let doc = try parse(html)
    return try doc.select(selector).first()?.attr("value")
}

func mealEat(pythonPath: String, ntlm_crawler: String, id: String, pwd: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    let formattedToday = dateFormatter.string(from: Date())

    let checkMealURL = "http://hr.rsquanta.com/QSMCHR/Attn/Query_Meal.aspx?Flag=6"
    let mealHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " get \(checkMealURL) \(id) \"\(pwd)\" | base64 -d"]).1
    
    if mealHtml.contains("_gvlblBusapp\">\(formattedToday)</span>") {
        return "Y"
    }

    let addMealURL = "\"http://hr.rsquanta.com/HR/AttnData/Modify_meal.aspx?Site=QSMC&RoleType=6&languageType=zh-CN&languageType=zh-CN\""
    let addMealHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " get \(addMealURL) \(id) \"\(pwd)\" | base64 -d"]).1
    
    guard let vsAdd = try? parseValue(from: addMealHtml, selector: "input[name='__VIEWSTATE']"),
          let vsgAdd = try? parseValue(from: addMealHtml, selector: "input[name='__VIEWSTATEGENERATOR']"),
          let evAdd = try? parseValue(from: addMealHtml, selector: "input[name='__EVENTVALIDATION']") else {
        return "N"
    }

    let postArgs = """
'{"__EVENTTARGET": "", "__EVENTARGUMENT": "", "__LASTFOCUS": "", "__VIEWSTATE": "\(vsAdd)", "__VIEWSTATEGENERATOR": "\(vsgAdd)", "__EVENTVALIDATION": "\(evAdd)", "txtBusapp": "\(formattedToday)", "btnAddNew": "AddNew"}'
"""
    let addMealPostHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " post \(addMealURL) \(id) \"\(pwd)\" \(postArgs) | base64 -d"]).1

    guard let vsSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__VIEWSTATE']"),
          let vsgSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__VIEWSTATEGENERATOR']"),
          let evSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__EVENTVALIDATION']") else {
        return "N"
    }

    let saveArgs = """
'{"__EVENTTARGET": "", "__EVENTARGUMENT": "", "__LASTFOCUS": "", "__VIEWSTATE": "\(vsSave)", "__VIEWSTATEGENERATOR": "\(vsgSave)", "__EVENTVALIDATION": "\(evSave)", "txtBusapp": "\(formattedToday)", "btnSave": "Save"}'
"""
    let saveMealPostHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " post \(addMealURL) \(id) \"\(pwd)\" \(saveArgs) | base64 -d"]).1

    if saveMealPostHtml.contains(">新增成功</span>") {
        return "Y"
    }
    
    return "N"
}
