import SwiftUI

/// A lightweight drop-in property wrapper that wraps SwiftUI.State without triggering
/// the Swift 6 external macro plugin requirement (`SwiftUIMacros.StateMacro`), which is absent
/// in standalone Command Line Tools SDKs.
@propertyWrapper
public struct LocalState<Value>: DynamicProperty {
    private var state: SwiftUI.State<Value>

    public init(wrappedValue: Value) {
        self.state = SwiftUI.State(initialValue: wrappedValue)
    }

    public var wrappedValue: Value {
        get { state.wrappedValue }
        nonmutating set { state.wrappedValue = newValue }
    }

    public var projectedValue: Binding<Value> {
        state.projectedValue
    }
}
