import Foundation

public func makeTimer(delay: TimeInterval,
                      queue: DispatchQueue,
                      handler: @escaping () -> Void)
    -> DispatchSourceTimer
{
    let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
    timer.schedule(deadline: DispatchTime.now() + delay)
    timer.setEventHandler {
        handler()
    }
    timer.resume()
    return timer
}
