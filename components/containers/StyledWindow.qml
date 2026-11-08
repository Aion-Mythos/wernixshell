import Quickshell
import Quickshell.Wayland
import Vaxison.Config

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    required property string name

    WlrLayershell.namespace: `vaxison-${name}`
    color: "transparent"

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name
}
