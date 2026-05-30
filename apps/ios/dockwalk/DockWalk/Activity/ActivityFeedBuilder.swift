import Foundation

enum ActivityFeedBuilder {

  /// Merges audit trail + local pending queue, newest first.
  static func buildTimeline(
    auditEvents: [AuditEventItem],
    pendingActions: [QueuedSyncAction],
    catalog: InventoryCatalogStore = .shared
  ) -> [ActivityTimelineEntry] {
    var entries: [ActivityTimelineEntry] = []

    for event in auditEvents {
      entries.append(.audit(event))
    }

    for action in pendingActions {
      entries.append(.pending(action))
    }

    return entries.sorted { $0.sortDate > $1.sortDate }
  }

  static func recentActivityItems(
    from entries: [ActivityTimelineEntry],
    limit: Int = 5
  ) -> [TodayModels.RecentActivityItem] {
    entries.prefix(limit).map { entry in
      switch entry {
      case .audit(let event):
        return TodayModels.RecentActivityItem(
          id: "audit-\(event.id)",
          title: event.action.capitalized + " · " + event.entityType.replacingOccurrences(of: "_", with: " "),
          meta: event.payloadSummary ?? "Recorded on server",
          barcode: event.primaryIdentifier,
          timeLabel: event.createdAt?.formatted(date: .omitted, time: .shortened) ?? "—",
          isLive: false,
          tone: .muted
        )
      case .pending(let action):
        return TodayModels.RecentActivityItem(
          id: "pending-\(action.id.uuidString)",
          title: action.summary,
          meta: "\(action.kindDisplayName) · pending sync",
          barcode: action.primaryBarcode,
          timeLabel: action.createdAt.formatted(date: .omitted, time: .shortened),
          isLive: true,
          tone: .pending
        )
      }
    }
  }

  static func enrichAuditEvent(
    _ item: AuditEventItem,
    pendingActions: [QueuedSyncAction],
    catalog: InventoryCatalogStore = .shared
  ) -> AuditEventItem {
    var identifier = item.primaryIdentifier

    if identifier == nil, let entityId = item.entityId {
      identifier = barcodeFromPending(entityId: entityId, actions: pendingActions)
    }

    if identifier == nil, let sku = item.payloadSKU {
      identifier = catalog.item(matchingSKU: sku)?.upc ?? sku
    }

    guard identifier != item.primaryIdentifier else { return item }

    return AuditEventItem(
      id: item.id,
      action: item.action,
      entityType: item.entityType,
      entityId: item.entityId,
      createdAt: item.createdAt,
      facilityId: item.facilityId,
      actorUserId: item.actorUserId,
      payloadSummary: item.payloadSummary,
      detailLines: item.detailLines,
      primaryIdentifier: identifier,
      payloadSKU: item.payloadSKU,
      payloadEventType: item.payloadEventType
    )
  }

  private static func barcodeFromPending(entityId: String, actions: [QueuedSyncAction]) -> String? {
    for action in actions {
      if action.inboundLoadId == entityId {
        return action.primaryBarcode
      }
      if action.receivingEventPayload?.inboundShipmentId == entityId {
        return action.primaryBarcode
      }
      if action.outboundOrderId == entityId {
        return action.primaryBarcode
      }
    }
    return nil
  }
}

enum ActivityTimelineEntry: Identifiable {
  case audit(AuditEventItem)
  case pending(QueuedSyncAction)

  var id: String {
    switch self {
    case .audit(let event): return "audit-\(event.id)"
    case .pending(let action): return "pending-\(action.id.uuidString)"
    }
  }

  var sortDate: Date {
    switch self {
    case .audit(let event): return event.createdAt ?? .distantPast
    case .pending(let action): return action.createdAt
    }
  }
}

private extension InventoryCatalogStore {
  func item(matchingSKU sku: String) -> InventoryItem? {
    let q = sku.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return nil }
    return items.first { $0.sku.lowercased() == q }
  }
}
