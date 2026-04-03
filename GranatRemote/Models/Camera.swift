import Foundation

struct Camera: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var url: String
    var panelGroupId: String? // nil = not tied to a panel group
}

class CameraStore: ObservableObject {
    static let shared = CameraStore()

    @Published var cameras: [Camera] = []

    private let key = "saved_cameras_v1"

    init() { load() }

    func cameras(for panelGroupId: String) -> [Camera] {
        cameras.filter { $0.panelGroupId == panelGroupId }
    }

    func add(_ cam: Camera) {
        cameras.append(cam)
        save()
    }

    func update(_ cam: Camera) {
        guard let i = cameras.firstIndex(where: { $0.id == cam.id }) else { return }
        cameras[i] = cam
        save()
    }

    func delete(id: String) {
        cameras.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let d = try? JSONEncoder().encode(cameras) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let c = try? JSONDecoder().decode([Camera].self, from: d) else { return }
        cameras = c
    }
}
