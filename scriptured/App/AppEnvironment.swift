import Foundation

struct AppEnvironment {
    let bibleService: any BibleServicing
    let persistenceService: any PersistenceService
    let authenticationService: any AuthenticationService
    let widgetRefreshService: any WidgetRefreshService

    static let live = AppEnvironment(
        bibleService: BibleService(),
        persistenceService: LocalPersistenceService(),
        authenticationService: AppleAuthenticationService(),
        widgetRefreshService: WidgetRefreshServiceAdapter()
    )
}
