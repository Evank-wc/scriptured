import Foundation

protocol WidgetRefreshService {
    func refreshWidgets() async
}

struct WidgetRefreshServiceAdapter: WidgetRefreshService {
    func refreshWidgets() async {
    }
}
