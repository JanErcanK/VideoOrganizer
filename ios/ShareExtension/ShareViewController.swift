import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private let model = SharedLink()

    override func viewDidLoad() {
        super.viewDidLoad()
        let form = ShareForm(model: model, cancel: { [weak self] in
            self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
        }, save: { [weak self] in self?.store() })
        let child = UIHostingController(rootView: form)
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        child.didMove(toParent: self)

        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        let candidates = ["public.url", "public.plain-text"].flatMap { type in
            providers.filter { $0.hasItemConformingToTypeIdentifier(type) }.map { ($0, type) }
        }
        func load(_ index: Int) {
            guard index < candidates.count else {
                model.error = "Kein Videolink gefunden. Du kannst den Link hier einfügen."
                return
            }
            let (provider, type) = candidates[index]
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
                let text = (item as? URL)?.absoluteString ?? (item as? String) ?? ""
                DispatchQueue.main.async {
                    if let url = SharedLink.extract(text) {
                        if self.model.url.isEmpty { self.model.url = url.absoluteString }
                    } else { load(index + 1) }
                }
            }
        }
        load(0)
    }

    private func store() {
        guard let url = SharedLink.extract(model.url) else {
            model.error = "Bitte einen gültigen Videolink eingeben."
            return
        }
        let raw = model.duration.trimmingCharacters(in: .whitespacesAndNewlines)
        var seconds: Int?
        if !raw.isEmpty {
            guard raw.range(of: #"^\d{1,7}(:[0-5]\d){0,2}$"#, options: .regularExpression) != nil else {
                model.error = "Gib die Dauer in Sekunden oder als Min:Sek ein."
                return
            }
            seconds = raw.split(separator: ":").reduce(0) { $0 * 60 + (Int($1) ?? 0) }
            guard (seconds ?? 0) > 0 else { model.error = "Die Dauer muss größer als null sein."; return }
        }
        model.addTag()
        let id = UUID().uuidString
        var entry: [String: Any] = ["id": id, "url": url.absoluteString,
            "title": model.title.trimmingCharacters(in: .whitespacesAndNewlines), "note": model.note,
            "tags": model.names.filter { model.selected.contains($0) },
            "created": Int64(Date().timeIntervalSince1970 * 1000)]
        if let seconds = seconds { entry["seconds"] = seconds }
        do {
            let file = try SharedInbox.folder.appendingPathComponent(id + ".json")
            try JSONSerialization.data(withJSONObject: entry).write(to: file, options: .atomic)
            extensionContext?.completeRequest(returningItems: nil)
        } catch { model.error = "Speichern fehlgeschlagen. Bitte erneut versuchen." }
    }
}

private final class SharedLink: ObservableObject {
    @Published var url = ""
    @Published var title = ""
    @Published var note = ""
    @Published var duration = ""
    @Published var names = SharedInbox.tagNames()
    @Published var selected = Set<String>()
    @Published var newTag = ""
    @Published var error = ""

    static func extract(_ text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.matches(in: text, options: [], range: range).compactMap { $0.url }
            .first { ["http","https"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil && $0.user == nil }
    }

    func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        let existing = names.first { $0.caseInsensitiveCompare(tag) == .orderedSame }
        if existing == nil { names.append(tag) }
        selected.insert(existing ?? tag)
        newTag = ""
    }
}

private struct ShareForm: View {
    @ObservedObject var model: SharedLink
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Videolink")) {
                    TextField("https://…", text: $model.url).keyboardType(.URL)
                        .autocapitalization(.none).disableAutocorrection(true)
                    TextField("Titel (optional)", text: $model.title)
                }
                Section(header: Text("Tags")) {
                    ForEach(model.names, id: \.self) { tag in
                        Button(action: {
                            if model.selected.contains(tag) { model.selected.remove(tag) }
                            else { model.selected.insert(tag) }
                        }) { HStack { Text(tag); Spacer(); if model.selected.contains(tag) { Image(systemName: "checkmark") } } }
                    }
                    HStack {
                        TextField("Eigenen Tag erstellen", text: $model.newTag, onCommit: model.addTag)
                        Button(action: model.addTag) { Image(systemName: "plus.circle") }.accessibilityLabel("Tag hinzufügen")
                    }
                }
                Section(header: Text("Kommentar")) { TextField("Was möchtest du dir merken?", text: $model.note) }
                Section(header: Text("Videodauer")) { TextField("Min:Sek oder Sekunden (optional)", text: $model.duration) }
                if !model.error.isEmpty { Text(model.error).foregroundColor(.red) }
            }
            .navigationBarTitle("Video merken", displayMode: .inline)
            .navigationBarItems(leading: Button("Abbrechen", action: cancel), trailing: Button("Speichern", action: save).disabled(model.url.isEmpty))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(Color(red: 0.14, green: 0.29, blue: 0.24))
    }
}