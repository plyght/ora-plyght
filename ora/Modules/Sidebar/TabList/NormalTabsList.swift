import SwiftData
import SwiftUI

struct NormalTabsList: View {
    let tabs: [Tab]
    @Binding var draggedItem: UUID?
    let onDrag: (UUID) -> NSItemProvider
    let onSelect: (Tab) -> Void
    let onPinToggle: (Tab) -> Void
    let onFavoriteToggle: (Tab) -> Void
    let onClose: (Tab) -> Void
    let onMoveToContainer:
        (
            Tab,
            TabContainer
        ) -> Void
    let onAddNewTab: () -> Void
    @Query var containers: [TabContainer]
    @EnvironmentObject var tabManager: TabManager

    private var treeSortedTabs: [Tab] {
        var result: [Tab] = []
        var processed = Set<UUID>()

        func addTabWithChildren(_ tab: Tab) {
            guard !processed.contains(tab.id) else { return }
            processed.insert(tab.id)
            result.append(tab)

            let children = tab.getChildren(from: tabManager).sorted { $0.order < $1.order }
            for child in children {
                addTabWithChildren(child)
            }
        }

        let rootTabs = tabs.filter { $0.parentTabId == nil }.sorted { $0.order < $1.order }
        for rootTab in rootTabs {
            addTabWithChildren(rootTab)
        }

        return result
    }

    var body: some View {
        Section {
            NewTabButton(addNewTab: onAddNewTab)
            ForEach(treeSortedTabs) { tab in
                TabItem(
                    tab: tab,
                    isSelected: tabManager.isActive(tab),
                    isDragging: draggedItem == tab.id,
                    onTap: { onSelect(tab) },
                    onPinToggle: { onPinToggle(tab) },
                    onFavoriteToggle: { onFavoriteToggle(tab) },
                    onClose: { onClose(tab) },
                    onMoveToContainer: { onMoveToContainer(tab, $0) },
                    availableContainers: containers
                )
                .onDrag { onDrag(tab.id) }
                .onDrop(
                    of: [.text],
                    delegate: TabDropDelegate(
                        item: tab,
                        draggedItem: $draggedItem,
                        targetSection: .normal
                    )
                )
            }
        }
        .onDrop(
            of: [.text],
            delegate: SectionDropDelegate(
                items: tabs,
                draggedItem: $draggedItem,
                targetSection: .normal,
                tabManager: tabManager
            )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: treeSortedTabs.map(\.id))
    }
}
