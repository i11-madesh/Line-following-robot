# PIC18F452 Line-Following Robot

**A three-sensor autonomous line follower programmed entirely in PIC18F452 assembly language.**

**Author:** Madesh J  
**Microcontroller:** Microchip PIC18F452  
**Programming:** MPASM assembly · MPLAB X IDE · PICkit 3  
**Clock:** 20 MHz external crystal

## Project overview

This project is a small, two-wheel robot designed to follow a **black line on a light surface**. Three digital infrared (IR) sensors detect the position of the line. A PIC18F452 reads these inputs and controls two DC geared motors through an L298N motor-driver module.

The robot uses **software PWM** for different left/right motor speeds, allowing gentle steering around curved sections of a track. The working assembly program also remembers the most recent correction direction and uses it to attempt to find the line again if all three sensors detect white.

> **Project status:** The assembled robot has been tested successfully following a black line. Performance on tighter corners and after completely losing the line depends on track geometry and sensor calibration.

## Features

- Three digital IR sensors for left, center and right line detection.
- Forward motion when the center sensor detects the line.
- Gentle left/right corrections using differential motor speeds.
- Software PWM implemented in PIC18 assembly (no Arduino libraries).
- Simple last-direction-based line-search behavior.
- Documented pin mapping for replicating or studying the project.

## Hardware used

| Component | Purpose |
|---|---|
| PIC18F452 (40-pin DIP) | Reads sensors and controls motors |
| 3 digital IR line-detection sensors | Detect black/white surface |
| L298N dual H-bridge module | Drives the left and right DC motors |
| 2 DC geared motors, wheels and caster | Robot movement and support |
| 20 MHz crystal + appropriate load capacitors | Microcontroller clock |
| 10 kΩ resistor on MCLR | Reset pull-up |
| Regulated 5 V logic supply | PIC and compatible sensor power |
| Motor supply suited to motor ratings | L298N motor-power input |
| PICkit 3, breadboard/wires, chassis | Programming and construction |

## Connections

### IR sensors → PIC18F452

| Sensor output | PIC port | PIC physical pin |
|---|---|---:|
| Left OUT | RB0 | 33 |
| Center OUT | RB1 | 34 |
| Right OUT | RB2 | 35 |

**Verified sensor polarity used by the working program:** `BLACK = LOW (0)` and `WHITE = HIGH (1)`.

### PIC18F452 → L298N

| PIC port | PIC physical pin | L298N signal | Function |
|---|---:|---|---|
| RD0 | 19 | IN1 | Left motor direction |
| RD1 | 20 | IN2 | Left motor direction |
| RD2 | 21 | IN3 | Right motor direction |
| RD3 | 22 | IN4 | Right motor direction |
| RC2 | 17 | ENA | Left motor software PWM |
| RC1 | 16 | ENB | Right motor software PWM |

| L298N outputs | Connection |
|---|---|
| OUT1, OUT2 | Left DC motor |
| OUT3, OUT4 | Right DC motor |

### Clock, reset, and power

- PIC **VDD**: pins **11, 32** → regulated 5 V; **VSS**: pins **12, 31** → ground.
- **MCLR**: pin **1** → 10 kΩ pull-up to regulated 5 V.
- **OSC1/OSC2**: pins **13, 14** → 20 MHz crystal with suitable load capacitors.
- PIC, sensors and L298N must share a **common ground**.
- The L298N motor supply must be compatible with the motors' voltage rating. **Do not apply motor battery voltage to PIC VDD.** The module's `+5V` terminal may be an input or output depending on its regulator/jumper configuration.

## Control logic

| Left sensor | Center sensor | Right sensor | Action |
|---|---|---|---|
| White | Black | White | Forward |
| Black | Black | White | Gentle left |
| Black | White | White | Gentle left |
| White | Black | Black | Gentle right |
| White | White | Black | Gentle right |
| Black | Black | Black | Forward |
| Black | White | Black | Forward |
| White | White | White | Search using last remembered direction |

The working program's PWM values are on a **0–255 scale**:

| Mode | Left motor duty | Right motor duty |
|---|---:|---:|
| Forward | 125 | 125 |
| Gentle left | 90 | 145 |
| Gentle right | 145 | 90 |
| Line search | 110 | 110 |

These values are **PWM duty settings**, not measured motor RPM. During ordinary left/right corrections, both motors rotate forward; one is slower than the other. In the lost-line routine, the motor directions depend on the last detected side, and the program has **no fixed search timeout**.

## Firmware

**Main source file:** `line_follower.asm`

The assembly program configures RB0–RB2 as digital inputs, RD0–RD3 as motor-direction outputs and RC2/RC1 as motor-enable outputs. It repeatedly reads the sensors, selects a movement routine and generates a 256-step software PWM frame.

### Build and program

1. Open **MPLAB X IDE** and create/select a project targeting the **PIC18F452** with an MPASM-compatible toolchain.
2. Add `line_follower.asm` to the project and build it.
3. Connect PICkit 3 to the programming pins (including **MCLR, RB6/PGC pin 39, RB7/PGD pin 40, VDD and GND**) according to the programmer and board documentation.
4. Program the PIC18F452, then confirm stable regulated logic power and correct sensor response.
5. Test motor commands with the robot's wheels lifted before trying a track.

> **Tip:** Keep the verified working `.asm` file unchanged as a backup before experimenting with new turning or recovery routines.

## Testing and results

The robot has been demonstrated following a simple black-line track using three IR sensors, the L298N, and PIC18F452 assembly code. The sensor inputs, motor-control signals and motor movements were tested during development.

For a reproducible demonstration, place the sensors at a consistent height above a high-contrast track and check that each sensor reliably changes state between black and white. Adjust speed only after confirming the motor direction and sensor mapping.

**Known limitations:** Reliable recovery after leaving the track and tight 90-degree corners have not been established as part of the confirmed working version.

## What I learned

- Programming and testing a PIC microcontroller in assembly language.
- Interfacing digital infrared sensors through PORTB.
- Driving two DC motors through an L298N H-bridge.
- Using software PWM for differential steering.
- Debugging pin mapping, input polarity, power connections and motor behavior.

---

**Developed by Madesh J** · Microprocessors and Microcontrollers course project(MPMC)
