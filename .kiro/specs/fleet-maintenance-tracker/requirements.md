# Requirements Document

## Introduction

Fleet Maintenance Tracker is a Flutter mobile application for small fleet owners in Indonesia managing cars and motorcycles. The app enables daily kilometer input tracking, automatic maintenance schedule calculations based on both distance and time intervals, comprehensive maintenance history recording, and proactive notifications alerting owners about upcoming maintenance needs in Indonesian language.

The core value proposition is predictive maintenance scheduling — the app calculates when each vehicle component (oil, tires, brake pads, etc.) needs servicing based on actual usage patterns (daily km input) and time elapsed since last service.

## Glossary

- **Km**: Kilometer, unit of distance measurement
- **IDR**: Indonesian Rupiah, currency unit
- **Armada**: Fleet of vehicles
- **Perawatan**: Maintenance/service
- **Ganti oli**: Oil change
- **Ganti ban**: Tire replacement
- **Kampas rem**: Brake pads
- **Bengkel**: Workshop/service center
- **BLoC**: Business Logic Component, a state management pattern in Flutter

## Requirements

### 1. Vehicle Management

#### Requirement 1.1: Add Vehicle
**Given** a user on the vehicle creation screen
**When** they provide a vehicle name, type (car/motorcycle), plate number, and year
**Then** a new vehicle is created with 0 total mileage and the current date as creation date

**Acceptance Criteria:**
- Vehicle name is required, max 50 characters
- Vehicle type must be either "car" or "motorcycle"
- Plate number follows Indonesian format (letters, space, digits, space, letters)
- Year must be between 1970 and current year + 1
- Vehicle is immediately available in the vehicle list after creation

#### Requirement 1.2: View Vehicle List
**Given** a user with one or more registered vehicles
**When** they open the app
**Then** they see a list of all vehicles with name, type, plate number, and total mileage

**Acceptance Criteria:**
- Vehicles are displayed with their current total mileage
- Each vehicle shows its type icon (car/motorcycle)
- The list shows the most urgent upcoming maintenance status per vehicle

#### Requirement 1.3: Edit Vehicle
**Given** a user viewing a vehicle's details
**When** they edit the vehicle name, plate number, or year
**Then** the vehicle information is updated

**Acceptance Criteria:**
- Same validation rules as vehicle creation apply
- Vehicle type cannot be changed after creation (would invalidate maintenance schedules)
- Total mileage cannot be manually edited (derived from mileage records)

#### Requirement 1.4: Delete Vehicle
**Given** a user viewing a vehicle's details
**When** they choose to delete the vehicle and confirm the action
**Then** the vehicle and all associated records are permanently removed

**Acceptance Criteria:**
- A confirmation dialog is shown before deletion
- Deletion cascades to all mileage records, maintenance records, schedules, and notifications
- The action is irreversible

### 2. Daily Mileage Tracking

#### Requirement 2.1: Record Daily Kilometers
**Given** a user with a registered vehicle
**When** they input the number of kilometers driven that day
**Then** the mileage is recorded and the vehicle's total mileage is updated

**Acceptance Criteria:**
- Km input must be greater than 0 and less than or equal to 2000
- Date defaults to today but can be set to a past date
- Date cannot be set to a future date
- Total vehicle mileage increases by the entered amount
- All maintenance schedules are recalculated after input

#### Requirement 2.2: One Record Per Day Per Vehicle
**Given** a user who already recorded mileage for a vehicle on a specific date
**When** they attempt to record mileage for the same vehicle and date
**Then** they are prompted to replace the existing record

**Acceptance Criteria:**
- System detects existing record for the same vehicle and date
- User is shown a confirmation dialog to replace
- If confirmed, the old record is replaced and totals are adjusted
- If cancelled, no changes are made

#### Requirement 2.3: View Mileage History
**Given** a user viewing a vehicle's details
**When** they navigate to the mileage history section
**Then** they see a chronological list of daily mileage records

**Acceptance Criteria:**
- Records show date, km driven, and any notes
- History can be filtered by date range
- Running total is visible
- Average daily km (last 30 days) is displayed

### 3. Maintenance Schedule Calculation

#### Requirement 3.1: Automatic Schedule Calculation
**Given** a vehicle with recorded mileage and maintenance history
**When** the system recalculates maintenance schedules
**Then** each applicable maintenance type shows remaining km and remaining days until due

**Acceptance Criteria:**
- Schedule uses both km interval and time interval (whichever triggers first)
- Remaining km = (last service km + interval km) - current total km
- Remaining days = (last service date + interval months) - today
- Overdue status is set when either remaining km <= 0 or remaining days <= 0
- Estimated due date is calculated using average daily km over last 30 days

#### Requirement 3.2: Vehicle-Type-Specific Maintenance Types
**Given** a vehicle of a specific type (car or motorcycle)
**When** maintenance schedules are calculated
**Then** only applicable maintenance types are included

**Acceptance Criteria:**
- Motorcycles include: oil change, tire replacement, brake pads, air filter, spark plug, chain lube, coolant, brake fluid, transmission
- Cars include all of the above except chain lube
- Default intervals follow Indonesian market standards as defined in the design document

#### Requirement 3.3: Schedule Recalculation Triggers
**Given** an existing set of maintenance schedules for a vehicle
**When** daily mileage is recorded OR maintenance is marked as completed
**Then** all schedules for that vehicle are recalculated

**Acceptance Criteria:**
- Recalculation happens automatically after mileage input
- Recalculation happens automatically after maintenance completion
- Only the affected vehicle's schedules are recalculated
- Schedules are sorted by urgency (overdue first, then by remaining km)

#### Requirement 3.4: View Maintenance Dashboard
**Given** a user viewing a vehicle's maintenance section
**When** the maintenance dashboard loads
**Then** all maintenance schedules are displayed sorted by urgency

**Acceptance Criteria:**
- Overdue items are highlighted in red at the top
- Warning items (within warning threshold) are highlighted in yellow
- Normal items show remaining km and estimated date
- Each item shows the maintenance type name in Indonesian

### 4. Maintenance History Recording

#### Requirement 4.1: Record Completed Maintenance
**Given** a user with a vehicle that has maintenance due or overdue
**When** they record a completed maintenance service
**Then** the maintenance is saved and the schedule resets for that type

**Acceptance Criteria:**
- Required: maintenance type, current mileage at service, service date
- Optional: cost (in IDR), notes, workshop name
- Service date cannot be in the future
- Mileage at service must be <= vehicle's current total mileage
- After recording, next due is calculated from the new service point

#### Requirement 4.2: View Maintenance History
**Given** a user viewing a vehicle's details
**When** they navigate to maintenance history
**Then** they see a chronological list of all past maintenance events

**Acceptance Criteria:**
- History shows service type, date, mileage at service, and cost
- History can be filtered by maintenance type
- Most recent services appear first
- Total maintenance cost is summarized

### 5. Proactive Notifications

#### Requirement 5.1: Schedule Maintenance Reminders
**Given** a vehicle with calculated maintenance schedules
**When** a schedule's estimated due date is within the warning threshold
**Then** a local notification is scheduled for the appropriate warning time

**Acceptance Criteria:**
- Notification is scheduled at (estimated due date - warning days) or (due by date - warning days), whichever is earlier
- Notification includes vehicle name, maintenance type, remaining km, and remaining time
- Notification message is in Indonesian format: "{type prefix} {vehicle name} harus {action} {remaining km}km / {remaining time} lagi"
- Notifications are rescheduled when mileage is updated or maintenance is completed

#### Requirement 5.2: Notification Content Format
**Given** a scheduled notification for an upcoming maintenance
**When** the notification fires
**Then** it displays a properly formatted Indonesian-language message

**Acceptance Criteria:**
- Message uses "Motor" prefix for motorcycles, "Mobil" for cars
- Maintenance action uses Indonesian terms (ganti oli, ganti ban, ganti kampas rem, etc.)
- Time remaining uses appropriate units (hari, minggu, bulan, tahun)
- Example: "Motor Vario 160 harus ganti ban 100km / 3 bulan lagi"

#### Requirement 5.3: Notification Permission Handling
**Given** a user who has not granted notification permissions
**When** the app needs to schedule notifications
**Then** the app requests permission and handles denial gracefully

**Acceptance Criteria:**
- Permission is requested on first need (not on app install)
- If denied, app shows an in-app banner suggesting to enable notifications
- App functions fully without notifications (uses in-app badges instead)
- App periodically prompts to re-enable notifications

### 6. Multi-Vehicle Support

#### Requirement 6.1: Independent Vehicle Tracking
**Given** a user with multiple vehicles registered
**When** they record mileage or maintenance for one vehicle
**Then** only that vehicle's data and schedules are affected

**Acceptance Criteria:**
- Operations on one vehicle do not modify another vehicle's records
- Each vehicle has independent mileage totals, history, and schedules
- Vehicle list shows individual status for each vehicle

#### Requirement 6.2: Fleet Overview
**Given** a user with multiple vehicles
**When** they view the main screen
**Then** they see a summary of all vehicles with their most urgent maintenance needs

**Acceptance Criteria:**
- Shows count of vehicles with overdue maintenance
- Shows count of vehicles with upcoming maintenance within warning threshold
- Allows quick navigation to any vehicle's detail screen

### 7. Performance

#### Requirement 7.1: Schedule Recalculation Speed
**Given** a vehicle with maintenance schedules
**When** schedules are recalculated after a mileage input
**Then** the recalculation completes within 500ms

**Acceptance Criteria:**
- Database queries use indexes on vehicleId and date columns
- Recalculation for a single vehicle completes within 500ms on mid-range devices

#### Requirement 7.2: App Startup Time
**Given** a user opening the app
**When** the app launches
**Then** the vehicle list is loaded within 2 seconds

**Acceptance Criteria:**
- App should load vehicle list within 2 seconds on mid-range devices
- Maintenance schedules load lazily when a vehicle is selected

### 8. Data Persistence

#### Requirement 8.1: Local Storage
**Given** a user with recorded data
**When** the app is closed and reopened
**Then** all data persists without loss

**Acceptance Criteria:**
- All data is stored locally using SQLite
- No internet connection required for any app functionality
- Data persists across app restarts and device reboots

#### Requirement 8.2: Data Integrity
**Given** the stored data in the database
**When** any operation modifies the data
**Then** referential integrity is maintained

**Acceptance Criteria:**
- Mileage total always equals sum of all mileage records for a vehicle
- Cascade deletion maintains referential integrity
- No orphaned records after vehicle deletion

### 9. Usability

#### Requirement 9.1: Language
**Given** a user interacting with the app
**When** any text is displayed
**Then** all text is in Indonesian (Bahasa Indonesia)

**Acceptance Criteria:**
- All user-facing text is in Indonesian (Bahasa Indonesia)
- Date formats follow Indonesian conventions (DD/MM/YYYY)
- Currency displays in IDR format

#### Requirement 9.2: Input Convenience
**Given** a user performing daily km input
**When** they interact with input fields
**Then** the interface is optimized for quick data entry

**Acceptance Criteria:**
- Daily km input is the primary action, accessible from the home screen
- Vehicle selection persists between sessions (last selected vehicle)
- Numeric keyboard opens for km and cost inputs
