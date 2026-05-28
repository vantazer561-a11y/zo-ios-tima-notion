import Foundation
import LocalAuthentication

/// Биометрическая аутентификация для приватных заметок.
@MainActor
final class BiometricAuth: ObservableObject {

    static let shared = BiometricAuth()

    enum BioKind {
        case faceID, touchID, opticID, passcodeOnly, none

        var title: String {
            switch self {
            case .faceID:       return "Face ID"
            case .touchID:      return "Touch ID"
            case .opticID:      return "Optic ID"
            case .passcodeOnly: return "Код-пароль"
            case .none:         return "Биометрия недоступна"
            }
        }

        var systemImage: String {
            switch self {
            case .faceID:       return "faceid"
            case .touchID:      return "touchid"
            case .opticID:      return "opticid"
            case .passcodeOnly: return "lock.fill"
            case .none:         return "lock.slash"
            }
        }
    }

    /// Какие заметки сейчас разблокированы в этой сессии приложения.
    @Published private(set) var unlockedIDs: Set<UUID> = []

    /// Тип доступной биометрии.
    func availableKind() -> BioKind {
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch ctx.biometryType {
            case .faceID:  return .faceID
            case .touchID: return .touchID
            #if compiler(>=5.9)
            case .opticID: return .opticID
            #endif
            default:       return .passcodeOnly
            }
        }
        if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcodeOnly
        }
        return .none
    }

    /// Запрос аутентификации для разблокировки заметки.
    /// При успехе кладёт `id` в `unlockedIDs` до конца сессии.
    @discardableResult
    func unlock(noteID: UUID, reason: String = "Разблокировать заметку") async -> Bool {
        if unlockedIDs.contains(noteID) { return true }
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Ввести код"
        var error: NSError?
        let policy: LAPolicy = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        do {
            let ok = try await ctx.evaluatePolicy(policy, localizedReason: reason)
            if ok { unlockedIDs.insert(noteID) }
            return ok
        } catch {
            return false
        }
    }

    /// Подтвердить намерение защитить/снять защиту с заметки.
    func confirmToggleProtection(reason: String) async -> Bool {
        let ctx = LAContext()
        var error: NSError?
        let policy: LAPolicy = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        do { return try await ctx.evaluatePolicy(policy, localizedReason: reason) }
        catch { return false }
    }

    /// Сбросить все разблокировки (например, при уходе приложения в фон).
    func lockAll() {
        unlockedIDs.removeAll()
    }

    /// Проверка — разблокирована ли заметка в текущей сессии.
    func isUnlocked(_ id: UUID) -> Bool {
        unlockedIDs.contains(id)
    }
}
