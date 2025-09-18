// MedPanel — minimal SwiftUI app that calls "med" commands and renders output
import SwiftUI

struct ContentView: View {
    @State private var query = "query.term=sepsis&page.size=3&fields=BriefTitle"
    @State private var output = "Ready"
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MedPanel").font(.title).bold()
            HStack {
                TextField("ClinicalTrials query…", text: $query)
                Button(busy ? "Running…" : "Run") { runCTGov() }.disabled(busy)
            }
            ScrollView {
                Text(output).font(.system(.body, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading)
            }.border(.secondary)
            HStack {
                Button("RxNorm: amoxicillin") { runRx() }
                Button("FHIR: Patient 123 (HAPI)") { runFHIR() }
            }
        }.padding().frame(width: 720, height: 420)
    }

    func run(_ args: [String]) {
        busy = true
        let task = Process()
        task.launchPath = "/bin/bash"
        let joined = (["-lc"] + ["PATH=$PATH med " + args.joined(separator: " ")])
        task.arguments = joined
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        output = String(data: data, encoding: .utf8) ?? ""
        busy = false
    }

    func runCTGov() { run(["ctgov","search", "\"\(query)\""]) }
    func runRx() { run(["rxnorm","rxcui","\"amoxicillin\""]) }
    func runFHIR() { run(["fhir","get","https://hapi.fhir.org/baseR4","\"Patient?_count=1\""]) }
}

@main
struct MedPanelApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
