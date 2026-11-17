import Foundation
import Amplify

/// The two shapes every write shares: "run it and give me the new id" and
/// "run it and tell me if it landed". One place for the Amplify result
/// plumbing so each mutation reads as its GraphQL document and nothing else.
extension APIService {
    /// Runs a create mutation and returns the created record's id at `path`.
    func createdId(_ request: GraphQLRequest<JSONValue>, at path: String) async -> String? {
        guard case .success(let data) = try? await Amplify.API.mutate(request: request),
              let id = data.value(at: path), case .string(let idStr) = id else { return nil }
        return idStr
    }

    /// Whether a mutation reached the backend, so optimistic UI can roll back.
    func mutateSucceeded(_ request: GraphQLRequest<JSONValue>) async -> Bool {
        guard case .success = try? await Amplify.API.mutate(request: request) else { return false }
        return true
    }

    /// Runs a create mutation, describing the failure for a user-facing toast.
    func createOutcome(_ request: GraphQLRequest<JSONValue>, at path: String) async -> WriteOutcome {
        do {
            switch try await Amplify.API.mutate(request: request) {
            case .success(let data):
                guard let id = data.value(at: path), case .string(let idStr) = id else {
                    return .failed(reason: "Unexpected response")
                }
                return .saved(id: idStr)
            case .failure(let error):
                return .failed(reason: error.errorDescription)
            }
        } catch {
            return .failed(reason: error.localizedDescription)
        }
    }
}
