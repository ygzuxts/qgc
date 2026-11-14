.pragma library

function label(value) {
    var text = String(value)
    switch (text) {
    case "Tiltrotor VTOL": return qsTranslate("ActuatorMetadata", "Tiltrotor VTOL")
    case "MC Motors": return qsTranslate("ActuatorMetadata", "MC Motors")
    case "Motors": return qsTranslate("ActuatorMetadata", "Motors")
    case "Control Surfaces": return qsTranslate("ActuatorMetadata", "Control Surfaces")
    case "Position X": return qsTranslate("ActuatorMetadata", "Position X")
    case "Position Y": return qsTranslate("ActuatorMetadata", "Position Y")
    case "Position Z": return qsTranslate("ActuatorMetadata", "Position Z")
    case "Tilted by": return qsTranslate("ActuatorMetadata", "Tilted by")
    case "Direction CCW": return qsTranslate("ActuatorMetadata", "Direction CCW")
    case "Type": return qsTranslate("ActuatorMetadata", "Type")
    case "Roll Scale": return qsTranslate("ActuatorMetadata", "Roll Scale")
    case "Pitch Scale": return qsTranslate("ActuatorMetadata", "Pitch Scale")
    case "Yaw Scale": return qsTranslate("ActuatorMetadata", "Yaw Scale")
    case "Trim": return qsTranslate("ActuatorMetadata", "Trim")
    case "Lock control surfaces in hover": return qsTranslate("ActuatorMetadata", "Lock control surfaces in hover")
    case "Configure": return qsTranslate("ActuatorMetadata", "Configure")
    case "Enabled": return qsTranslate("ActuatorMetadata", "Enabled")
    case "Disabled": return qsTranslate("ActuatorMetadata", "Disabled")
    case "None": return qsTranslate("ActuatorMetadata", "None")
    case "Left Aileron": return qsTranslate("ActuatorMetadata", "Left Aileron")
    case "Right Aileron": return qsTranslate("ActuatorMetadata", "Right Aileron")
    case "Elevator": return qsTranslate("ActuatorMetadata", "Elevator")
    case "Rudder": return qsTranslate("ActuatorMetadata", "Rudder")
    case "Function": return qsTranslate("ActuatorMetadata", "Function")
    case "Disarmed": return qsTranslate("ActuatorMetadata", "Disarmed")
    case "Minimum": return qsTranslate("ActuatorMetadata", "Minimum")
    case "Maximum": return qsTranslate("ActuatorMetadata", "Maximum")
    case "Failsafe": return qsTranslate("ActuatorMetadata", "Failsafe")
    case "Reversible": return qsTranslate("ActuatorMetadata", "Reversible")
    case "Reverse": return qsTranslate("ActuatorMetadata", "Reverse")
    case "ESCs": return qsTranslate("ActuatorMetadata", "ESCs")
    case "Servos": return qsTranslate("ActuatorMetadata", "Servos")
    case "Tilts": return qsTranslate("ActuatorMetadata", "Tilts")
    }
    var match = /^(Motor|Tilt|Servo) (\d+)$/.exec(text)
    if (match) {
        switch (match[1]) {
        case "Motor": return qsTranslate("ActuatorMetadata", "Motor %1").arg(match[2])
        case "Tilt": return qsTranslate("ActuatorMetadata", "Tilt %1").arg(match[2])
        case "Servo": return qsTranslate("ActuatorMetadata", "Servo %1").arg(match[2])
        }
    }
    match = /^Surface (\d+) \(Servo (\d+)\)$/.exec(text)
    if (match) return qsTranslate("ActuatorMetadata", "Surface %1 (Servo %2)").arg(match[1]).arg(match[2])
    return text
}
