import Observation

@Observable
final class ZoomController {
    enum ZoomLevel {
        case actualSize
        case fit
        case zoomIn
        case zoomOut
    }
    
    private(set) var scale = 1.0
    private var zoomLocked = false
    
    var fitScale = 1.0 {
        didSet {
            if zoomLocked { zoom(.fit) }    // live zoom if user selected zoom to fit
        }
    }
    
    var isActualSize: Bool { scale == 1.0 }
    var isZoomedToFit: Bool { scale == fitScale }
    
    func zoom(_ level: ZoomLevel) {
        scale = switch level {
        case .actualSize:
            1.0
        case .fit:
            fitScale
        case .zoomIn:
            scale * 1.25
        case .zoomOut:
            scale / 1.25
        }
        
        zoomLocked = (level == .fit)
    }
}
