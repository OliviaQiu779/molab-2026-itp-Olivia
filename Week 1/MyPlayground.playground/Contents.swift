import UIKit

//var greeting = "Hello, playground"

//let weather = ["☀️", "🌤️", "☁️", "🌨️", "❄️", "🌧️"]
//
//func checkWeather(_ weather: String) -> String {
//    if weather == "🌧️" {
//        return "Bring an umbrella!"
//    } else {
//        return "It's a \(weather) day!"
//    }
//}
//
//var today = ""
//
//while today != "🌧️" {
//    today = weather.randomElement()!
//    print(checkWeather(today))
//}

let weather = ["☀️", "🌤️", "☁️", "🌨️", "❄️", "🌧️"]

func checkWeather(weather: String) {
    if weather == "🌧️" {
        print("Bring an umbrella!")
    } else {
        print("It's a \(weather) day!")
    }
}

var today = ""

while today != "🌧️" {
    today = weather.randomElement()!
    checkWeather(weather: today)
}
