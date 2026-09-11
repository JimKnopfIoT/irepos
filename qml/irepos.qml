import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"
import "components"

// Shows the stored figures first, then asks the site for fresh ones.
ApplicationWindow {
    id: app

    initialPage: Component { OverviewPage { } }
    cover: Component { CoverPage { } }
    allowedOrientations: defaultAllowedOrientations

    Component.onCompleted: {
        Figures.reload()
        Figures.refresh()
    }
}
