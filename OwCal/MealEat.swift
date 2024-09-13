//
//  MealEat.swift
//  垃圾软件
//
//  Created by dog on 2024/9/9.
//

import Foundation

func parseValue(from html: String, selector: String) throws -> String? {
    let doc = try parse(html)
    return try doc.select(selector).first()?.attr("value")
}

func mealEat(id: String, pwd: String, execFilePath: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    let formattedToday = dateFormatter.string(from: Date())

    let checkMealURL = "http://hr.rsquanta.com/QSMCHR/Attn/Query_Meal.aspx?Flag=6"
    let mealHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "\(execFilePath) \(id) '\(pwd)' get '\(checkMealURL)' | base64 -d"]).1
    
    if mealHtml.contains("_gvlblBusapp\">\(formattedToday)</span>") {
        return "Y"
    }

    let addMealURL = "http://hr.rsquanta.com/HR/AttnData/Modify_meal.aspx?Site=QSMC&RoleType=6&languageType=zh-CN&languageType=zh-CN"
    let addMealHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "\(execFilePath) \(id) '\(pwd)' get '\(addMealURL)' | base64 -d"]).1
    
    guard let vsAdd = try? parseValue(from: addMealHtml, selector: "input[name='__VIEWSTATE']"),
          let vsgAdd = try? parseValue(from: addMealHtml, selector: "input[name='__VIEWSTATEGENERATOR']"),
          let evAdd = try? parseValue(from: addMealHtml, selector: "input[name='__EVENTVALIDATION']") else {
        return "N"
    }

    let postArgs = "'\(vsAdd)' '\(vsgAdd)' '\(evAdd)' '\(formattedToday)' AddNew"
    let addMealPostHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "\(execFilePath) \(id) '\(pwd)' post '\(addMealURL)' \(postArgs) | base64 -d"]).1

    guard let vsSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__VIEWSTATE']"),
          let vsgSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__VIEWSTATEGENERATOR']"),
          let evSave = try? parseValue(from: addMealPostHtml, selector: "input[name='__EVENTVALIDATION']") else {
        return "N"
    }

    let saveArgs = "'\(vsSave)' '\(vsgSave)' '\(evSave)' '\(formattedToday)' Save"
    let saveMealPostHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "\(execFilePath) \(id) '\(pwd)' post '\(addMealURL)' \(saveArgs) | base64 -d"]).1
    
    if saveMealPostHtml.contains(">新增成功</span>") {
        return "Y"
    }
    
    return "N"
}
