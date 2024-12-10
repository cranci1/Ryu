//
//  SettingsModuleView.swift
//  Ryu
//
//  Created by Francesco on 10/12/24.
//

import SwiftUI

struct SettingsModuleView: View {
    @State private var modules: [ModuleStruct] = []
    @State private var moduleURLs: [String: String] = [:]
    @State private var showingAddModuleAlert = false
    @State private var moduleURL = ""

    var body: some View {
        VStack {
            List {
                ForEach(modules, id: \.name) { module in
                    HStack {
                        if let url = URL(string: module.iconURL), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.trailing, 10)
                        }
                        VStack(alignment: .leading) {
                            Text(module.name)
                                .font(.headline)
                            Text("Version: \(module.version)")
                                .font(.subheadline)
                            Text("Author: \(module.author.name)")
                                .font(.subheadline)
                        }
                        Spacer()
                        Text(module.stream)
                            .font(.caption)
                            .padding(5)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .onDelete(perform: deleteModule)
            }
            .navigationBarTitle("Modules")
            .navigationBarItems(trailing: Button(action: {
                showAddModuleAlert()
            }) {
                Image(systemName: "plus")
            })
            .refreshable {
                refreshModules()
            }
        }
        .onAppear(perform: loadModules)
    }

    func showAddModuleAlert() {
        let alert = UIAlertController(title: "Add Module", message: "Enter the URL of the module JSON", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter URL"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let url = alert.textFields?.first?.text {
                fetchModule(from: url)
            }
        }))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    func fetchModule(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "No error description")")
                return
            }
            do {
                let module = try JSONDecoder().decode(ModuleStruct.self, from: data)
                saveModuleData(data, withName: module.name)
                DispatchQueue.main.async {
                    modules.append(module)
                    moduleURLs[module.name] = urlString
                    saveModuleURLs()
                }
            } catch {
                print("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    func saveModuleData(_ data: Data, withName name: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("\(name).json")
        do {
            try data.write(to: fileURL)
            print("File saved: \(fileURL)")
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
        }
    }

    func saveModuleURLs() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("moduleURLs.json")
        do {
            let data = try JSONEncoder().encode(moduleURLs)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save module URLs: \(error.localizedDescription)")
        }
    }

    func loadModules() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("moduleURLs.json")
        do {
            let data = try Data(contentsOf: fileURL)
            moduleURLs = try JSONDecoder().decode([String: String].self, from: data)
            for (name, _) in moduleURLs {
                loadModuleData(withName: name)
            }
        } catch {
            print("Failed to load module URLs: \(error.localizedDescription)")
        }
    }

    func loadModuleData(withName name: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("\(name).json")
        do {
            let data = try Data(contentsOf: fileURL)
            let module = try JSONDecoder().decode(ModuleStruct.self, from: data)
            modules.append(module)
        } catch {
            print("Failed to load module data: \(error.localizedDescription)")
        }
    }

    func refreshModules() {
        for (name, urlString) in moduleURLs {
            guard let url = URL(string: urlString) else { continue }
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Failed to fetch data: \(error?.localizedDescription ?? "No error description")")
                    return
                }
                do {
                    let module = try JSONDecoder().decode(ModuleStruct.self, from: data)
                    if let index = modules.firstIndex(where: { $0.name == name }) {
                        if modules[index].version != module.version {
                            DispatchQueue.main.async {
                                modules[index] = module
                                saveModuleData(data, withName: module.name)
                            }
                        }
                    }
                } catch {
                    print("Failed to decode JSON: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
    }

    func deleteModule(at offsets: IndexSet) {
        offsets.forEach { index in
            let module = modules[index]
            moduleURLs.removeValue(forKey: module.name)
        }
        modules.remove(atOffsets: offsets)
        saveModuleURLs()
    }
}
