import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData

/// Service responsible for syncing votes between Firestore and SwiftData.
/// Designed for Reddit-style up/down voting.
struct VoteService {
    private static var db: Firestore { Firestore.firestore() }

    // MARK: ‑ Public API
    /// Toggle an upvote (voteType = 1) for current user on the given post.
    static func toggleUpvote(postId: String, modelContext: ModelContext) async {
        await toggleVote(postId: postId, desiredType: 1, modelContext: modelContext)
    }

    /// Toggle a down-vote (voteType = ‑1).
    static func toggleDownvote(postId: String, modelContext: ModelContext) async {
        await toggleVote(postId: postId, desiredType: -1, modelContext: modelContext)
    }

    /// Get the local vote for quick UI rendering.
    static func localVote(for postId: String, modelContext: ModelContext) -> Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        let key = compositeId(uid: uid, postId: postId)
        let fetch = FetchDescriptor<LocalVote>(predicate: #Predicate { $0.id == key })
        return (try? modelContext.fetch(fetch).first?.voteType) ?? 0
    }

    /// Fetch vote state from Firestore (used on first display when local cache missing).
    static func remoteVote(for postId: String, modelContext: ModelContext) async -> Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        let voteRef = db.collection("news").document(postId)
            .collection("votes").document(uid)
        do {
            let snap = try await voteRef.getDocument()
            let type = (snap.data()? ["value"] as? Int) ?? 0
            // Persist locally for next launch
            await cacheRemoteVote(postId: postId, type: type, modelContext: modelContext)
            return type
        } catch {
            print("[VoteService] remoteVote error: \(error)")
            return 0
        }
    }

    /// Store a remote vote in SwiftData cache without altering counts.
    @MainActor
    static func cacheRemoteVote(postId: String, type: Int, modelContext: ModelContext) async {
        guard let uid = Auth.auth().currentUser?.uid, type != 0 else { return }
        let voteId = compositeId(uid: uid, postId: postId)
        do {
            let fetch = FetchDescriptor<LocalVote>(predicate: #Predicate { $0.id == voteId })
            if let existing = try modelContext.fetch(fetch).first {
                existing.voteType = type
                existing.timestamp = Date()
            } else {
                modelContext.insert(LocalVote(id: voteId, postId: postId, userId: uid, voteType: type))
            }
        } catch {
            print("[VoteService] cacheRemoteVote error: \(error)")
        }
    }

    // MARK: ‑ Internal helpers
    @MainActor
    private static func toggleVote(postId: String, desiredType: Int, modelContext: ModelContext) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let voteId = compositeId(uid: uid, postId: postId)
        let newsRef = db.collection("news").document(postId)
        let voteRef = newsRef.collection("votes").document(uid)

        do {
            let snapshot = try await voteRef.getDocument()
            let prevType = (snapshot.data()? ["value"] as? Int) ?? 0
            var newType = desiredType
            if prevType == desiredType {
                // Undo vote
                newType = 0
                try await voteRef.delete()
            } else {
                // Upsert / update vote doc
                try await voteRef.setData([
                    "userId": uid,
                    "value": desiredType,
                    "timestamp": Date().timeIntervalSince1970
                ])
            }

            // Compute delta for likesCount (e.g., +1, -1, +2, -2)
            let delta = newType - prevType

            // Update likesCount in Firestore atomically
            if delta != 0 {
                try await newsRef.updateData(["likesCount": FieldValue.increment(Int64(delta))])
            }

            // Sync local vote cache & likes count
            syncLocal(voteId: voteId, postId: postId, uid: uid, type: newType, delta: delta, context: modelContext)
        } catch {
            print("[VoteService] Firestore error: \(error)")
        }
    }

    private static func syncLocal(voteId: String, postId: String, uid: String, type: Int, delta: Int, context: ModelContext) {
        do {
            let fetch = FetchDescriptor<LocalVote>(predicate: #Predicate { $0.id == voteId })
            if let local = try context.fetch(fetch).first {
                if type == 0 {
                    context.delete(local)
                } else {
                    local.voteType = type
                    local.timestamp = Date()
                }
            } else if type != 0 {
                context.insert(LocalVote(id: voteId, postId: postId, userId: uid, voteType: type))
            }

            // Update LocalNews likesCount
            if delta != 0 {
                let newsFetch = FetchDescriptor<LocalNews>(predicate: #Predicate { $0.id == postId })
                if let localNews = try context.fetch(newsFetch).first {
                    localNews.likesCount += delta
                }
            }
        } catch {
            print("[VoteService] Local sync error: \(error)")
        }
    }

    private static func compositeId(uid: String, postId: String) -> String { "\(uid)_\(postId)" }
}
