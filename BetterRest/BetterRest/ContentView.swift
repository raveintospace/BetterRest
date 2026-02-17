//
//  ContentView.swift
//  BetterRest
//
//  Created by Uri on 11/2/26.
//

import CoreML
import SwiftUI

struct ContentView: View {

    @State private var wakeUp: Date = defaultWakeTime
    @State private var sleepAmount: Double = 8.0
    @State private var coffeeAmount: Int = 1

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    // Static so it can be used as wakeUp property value
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }

    var body: some View {
        NavigationStack {
            Form {
                wakeUpSelector
                amountOfSleepSelector
                dailyCoffeeSelector
            }
            .navigationTitle("BetterRest")
            .toolbar {
                Button("Calculate", action: calculateBedTime)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {

    private func calculateBedTime() {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)

            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60 // convert to seconds
            let minute = (components.minute ?? 0) * 60 // convert to seconds

            // the sleep the user needs, computed by CoreML
            let prediction = try model.prediction(wake: Double(hour + minute),
                                                  estimatedSleep: sleepAmount,
                                                  coffee: Double(coffeeAmount))

            let sleepTime = wakeUp - prediction.actualSleep

            alertTitle = "Your ideal bedtime is..."
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
        }

        showAlert = true
    }

    private var wakeUpSelector: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("When do you want to wake up?")
                .font(.headline)

            DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private var amountOfSleepSelector: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Desired amount of sleep")
                .font(.headline)

            Stepper("\(sleepAmount.formatted()) hours",
                    value: $sleepAmount,
                    in: 4...12,
                    step: 0.25)
        }
    }

    private var dailyCoffeeSelector: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily coffee intake")
                .font(.headline)

            Stepper("^[\(coffeeAmount) cup](inflect: true)", value: $coffeeAmount, in: 1...20)
        }
    }
}
