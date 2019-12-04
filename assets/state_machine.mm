stateDiagram
    state "TransitionEvent - %{event: :input_received}" as AcceptInput
    state "TransitionEvent - :success" as DoLookup
    state "Error - :invalid_lookup" as InvalidLookupError
    state "Error - :network_error" as NetworkError
    [*] --> AcceptInput
    AcceptInput --> DoLookup: input_received
    DoLookup --> InvalidLookupError: invalid_lookup
    DoLookup --> NetworkError: network_error
    DoLookup --> DispenseNosh: success
    NetworkError --> ShowError
    InvalidLookupError --> ShowError
    ShowError --> AcceptInput
    DispenseNosh --> [*]
