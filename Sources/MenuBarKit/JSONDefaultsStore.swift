import Foundation

public protocol DefaultInitializable {
    init()
}

/// Persists one Codable value as JSON under a single UserDefaults key. Missing or undecodable data yields `Value()`.
public final class JSONDefaultsStore<Value: Codable & DefaultInitializable> {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "config") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> Value {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(Value.self, from: data)
        else { return Value() }
        return value
    }

    public func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
