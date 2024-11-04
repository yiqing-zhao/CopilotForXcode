import Combine
import SwiftUI

class DebouncedBinding<T> {
    private let subject = PassthroughSubject<T, Never>()
    private let cancellable: AnyCancellable
    private let wrappedBinding: Binding<T>

    init(_ binding: Binding<T>, handler: @escaping (T) -> Void) {
        self.wrappedBinding = binding
        self.cancellable = subject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { handler($0) }
    }

    var binding: Binding<T> {
        return Binding(
            get: { self.wrappedBinding.wrappedValue },
            set: {
                  self.wrappedBinding.wrappedValue = $0
                  self.subject.send($0)
            }
        )
    }
}
