import Observation

@Observable
final class ZoomController {
    var scale: Double
    var actualSize: Double
    
    init(scale: Double = 1.0, actualSize: Double = 1.0) {
        self.scale = scale
        self.actualSize = actualSize
    }
    
    var isActualSize: Bool { scale == actualSize }
    var isZoomedToFit: Bool { scale == 1.0 }
    
    enum ZoomLevel {
        case actualSize
        case fit
        case zoomIn
        case zoomOut
    }
    
    func zoom(_ level: ZoomLevel) {
        switch level {
        case .actualSize:
            scale = actualSize
        case .fit:
            scale = 1.0
        case .zoomIn:
            scale *= 1.25
        case .zoomOut:
            scale /= 1.25
        }
    }
}
